class OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_offer, only: [ :update, :accept, :decline, :complete, :cancel, :destroy ]

  def create
    @item = Item.find(params[:item_id])

    if @item.user == current_user
      redirect_to @item, alert: "You cannot make an offer on your own item."
      return
    end

    if @item.removed? || @item.user.banned? || @item.status != "available"
      redirect_to @item, alert: "This item is not accepting offers right now."
      return
    end

    if @item.offers.exists?(buyer: current_user)
      redirect_to @item, alert: "You already have an offer for this item. Update it instead."
      return
    end

    @offer = @item.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.seller = @item.user

    # for an offer, convert to hkd from the current selected currency
    submitted_currency = params[:offer_currency].presence || current_currency_code
    @offer.price = Currency.convert_to_hkd(@offer.price.to_d, submitted_currency)

    if @offer.save
      redirect_to @item, notice: "Success! Your offer of #{helpers.display_price(@offer.price)} was sent."
    else
      redirect_to @item, alert: "Failed to send offer. Ensure the price is valid."
    end
  end

  def update
    unless @offer.editable_by_buyer?(current_user)
      redirect_to @offer.item, alert: "You cannot modify this offer right now."
      return
    end

    @offer.assign_attributes(offer_params)

    submitted_currency = params[:offer_currency].presence || current_currency_code
    @offer.price = Currency.convert_to_hkd(@offer.price.to_d, submitted_currency)
    @offer.status = "pending" if @offer.declined? || @offer.failed?

    if @offer.save
      Notification.create(recipient: @offer.seller, actor: current_user, action: "offer_updated", notifiable: @offer)
      sync_offer_notice_to_conversation(@offer, "offer_updated")
      redirect_to @offer.item, notice: "Your offer was updated to #{helpers.display_price(@offer.price)}."
    else
      redirect_to @offer.item, alert: @offer.errors.full_messages.to_sentence
    end
  end

  def accept
    return unless current_user == @offer.seller

    if @offer.update(status: "accepted")
      @offer.item.update(status: "pending_dropoff")

      Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_accepted", notifiable: @offer)
      sync_offer_notice_to_conversation(@offer, "offer_accepted")
      redirect_to dashboard_path, notice: "Offer accepted! Item reserved. Waiting for the buyer's PIN."
    end
  end

  def decline
    return unless current_user == @offer.seller

    @offer.update(status: "declined")
    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_declined", notifiable: @offer)
    redirect_to dashboard_path, notice: "Offer declined."
  end

  def cancel
    return unless current_user == @offer.seller

    @offer.update(status: "failed")
    @offer.item.update(status: "available")

    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_cancelled", notifiable: @offer)
    sync_offer_notice_to_conversation(@offer, "offer_cancelled")
    redirect_to dashboard_path, alert: "Transaction cancelled. The item is back on the market."
  end

  def complete
    return unless current_user == @offer.seller

    if params[:meetup_code] == @offer.meetup_code
      @offer.update(status: "completed")
      @offer.item.update(status: "sold", sold_at: Time.current)
      @offer.item.offers.where(status: "pending").update_all(status: "declined")

      Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_completed", notifiable: @offer)
      sync_offer_notice_to_conversation(@offer, "offer_completed")
      redirect_to dashboard_path, notice: "Transaction Complete! Item officially sold.", status: :see_other
    else
      redirect_to dashboard_path, alert: "Incorrect PIN. Please try again.", status: :see_other
    end
  end

  def destroy
    unless @offer.withdrawable_by_buyer?(current_user)
      redirect_back fallback_location: @offer.item, alert: "You cannot withdraw this offer right now."
      return
    end

    withdrawn_item = @offer.item
    withdrawn_price = @offer.price
    withdrawn_seller = @offer.seller

    Offer.transaction do
      Notification.where(notifiable: @offer).delete_all
      @offer.destroy!
      Notification.create!(
        recipient: withdrawn_seller,
        actor: current_user,
        action: "offer_withdrawn",
        notifiable: withdrawn_item,
        amount_hkd: withdrawn_price
      )
    end

    redirect_back fallback_location: withdrawn_item, notice: "Your offer was withdrawn."
  end

  private

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:price)
  end

  def sync_offer_notice_to_conversation(offer, notice_type)
    conversation = Conversation.find_by(item: offer.item, buyer: offer.buyer, seller: offer.seller)
    return if conversation.blank?

    content =
      if notice_type == "offer_updated"
        Message.offer_update_notice_content(offer.price)
      else
        Message.offer_status_notice_content(notice_type)
      end

    conversation.messages.create(
      user: current_user,
      content: content
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      conversation,
      target: view_context.dom_id(conversation, :offer_value),
      partial: "conversations/offer_value",
      locals: { conversation: conversation, offer: offer }
    )
  end
end
