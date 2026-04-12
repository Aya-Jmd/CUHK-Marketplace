class OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_offer, only: [ :update, :accept, :decline, :complete, :cancel, :destroy ]

  def create
    @item = Item.find(params[:item_id])

    unless @item.visible_to?(current_user)
      redirect_to items_path, alert: "This item is no longer available."
      return
    end

    if @item.user == current_user
      redirect_to @item, alert: "You cannot make an offer on your own item."
      return
    end

    if @item.removed? || @item.user.banned? || @item.status != "available"
      redirect_to @item, alert: "This item is not accepting offers right now."
      return
    end

    existing_offer = @item.offers.find_by(buyer: current_user)

    if existing_offer.present? && !existing_offer.declined?
      redirect_to @item, alert: "You already have an offer for this item. Update it instead."
      return
    end

    reopened_declined_offer = existing_offer&.declined?

    @offer = existing_offer || @item.offers.build
    @offer.assign_attributes(offer_params)
    @offer.buyer = current_user
    @offer.seller = @item.user
    @offer.status = "pending" if reopened_declined_offer

    # for an offer, convert to hkd from the current selected currency
    submitted_currency = params[:offer_currency].presence || current_currency_code
    @offer.price = Currency.convert_to_hkd(@offer.price.to_d, submitted_currency)

    if @offer.save
      Notification.create(recipient: @offer.seller, actor: current_user, action: "offer_created", notifiable: @offer) if reopened_declined_offer
      sync_offer_notice_to_conversation(
        item: @offer.item,
        buyer: @offer.buyer,
        seller: @offer.seller,
        actor: current_user,
        notice_type: "offer_created",
        amount_hkd: @offer.price
      )
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
      sync_offer_notice_to_conversation(
        item: @offer.item,
        buyer: @offer.buyer,
        seller: @offer.seller,
        actor: current_user,
        notice_type: "offer_updated",
        amount_hkd: @offer.price
      )
      redirect_to @offer.item, notice: "Your offer was updated to #{helpers.display_price(@offer.price)}."
    else
      redirect_to @offer.item, alert: @offer.errors.full_messages.to_sentence
    end
  end

  def accept
    return redirect_to(dashboard_path, alert: "You are not allowed to manage this offer.") unless current_user == @offer.seller

    error_message = nil

    Offer.transaction do
      @offer.lock!
      item = @offer.item
      item.lock!

      error_message = acceptance_error_for(@offer, item)
      raise ActiveRecord::Rollback if error_message

      @offer.update!(status: "accepted")
      item.update!(status: "pending_dropoff")
    end

    if error_message
      redirect_to dashboard_path, alert: error_message, status: :see_other
      return
    end

    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_accepted", notifiable: @offer)
    sync_offer_notice_to_conversation(
      item: @offer.item,
      buyer: @offer.buyer,
      seller: @offer.seller,
      actor: current_user,
      notice_type: "offer_accepted"
    )
    redirect_to dashboard_path, notice: "Offer accepted! Item reserved. Waiting for the buyer's PIN."
  end

  def decline
    return redirect_to(dashboard_path, alert: "You are not allowed to manage this offer.") unless current_user == @offer.seller
    return redirect_to(dashboard_path, alert: "This offer can no longer be declined.", status: :see_other) unless @offer.pending?

    if @offer.update(status: "declined")
      Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_declined", notifiable: @offer)
      sync_offer_notice_to_conversation(
        item: @offer.item,
        buyer: @offer.buyer,
        seller: @offer.seller,
        actor: current_user,
        notice_type: "offer_declined"
      )
      redirect_to dashboard_path, notice: "Offer declined."
    end
  end

  def cancel
    return redirect_to(dashboard_path, alert: "You are not allowed to manage this offer.") unless current_user == @offer.seller || current_user == @offer.buyer

    error_message = nil

    Offer.transaction do
      @offer.lock!
      item = @offer.item
      item.lock!

      error_message = cancellation_error_for(@offer, item)
      raise ActiveRecord::Rollback if error_message

      @offer.update!(status: "failed")
      next_item_status = item.offers.where(status: "accepted").where.not(id: @offer.id).exists? ? "pending_dropoff" : "available"
      item.update!(status: next_item_status)
    end

    if error_message
      redirect_to dashboard_path, alert: error_message, status: :see_other
      return
    end

    cancellation_recipient = current_user == @offer.seller ? @offer.buyer : @offer.seller

    Notification.create(recipient: cancellation_recipient, actor: current_user, action: "offer_cancelled", notifiable: @offer)
    sync_offer_notice_to_conversation(
      item: @offer.item,
      buyer: @offer.buyer,
      seller: @offer.seller,
      actor: current_user,
      notice_type: "offer_cancelled"
    )
    redirect_to dashboard_path, alert: "Transaction cancelled. The item is back on the market."
  end

  def complete
    return redirect_to(dashboard_path, alert: "You are not allowed to manage this offer.") unless current_user == @offer.seller

    submitted_meetup_code = params[:meetup_code].to_s

    unless submitted_meetup_code.match?(/\A\d{4}\z/)
      redirect_to dashboard_path, alert: "PIN must be exactly 4 digits.", status: :see_other
      return
    end

    error_message = nil

    Offer.transaction do
      @offer.lock!
      item = @offer.item
      item.lock!

      error_message = completion_error_for(@offer, item)
      raise ActiveRecord::Rollback if error_message

      stored_meetup_code = @offer.meetup_code.to_s
      unless stored_meetup_code.match?(/\A\d{4}\z/) &&
          ActiveSupport::SecurityUtils.secure_compare(submitted_meetup_code, stored_meetup_code)
        error_message = "Incorrect PIN. Please try again."
        raise ActiveRecord::Rollback
      end

      @offer.update!(status: "completed")
      item.update!(status: "sold", sold_at: Time.current)
      item.offers.where.not(id: @offer.id).where(status: %w[ pending accepted ]).update_all(status: "declined", updated_at: Time.current)
    end

    if error_message
      redirect_to dashboard_path, alert: error_message, status: :see_other
      return
    end

    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_completed", notifiable: @offer)
    sync_offer_notice_to_conversation(
      item: @offer.item,
      buyer: @offer.buyer,
      seller: @offer.seller,
      actor: current_user,
      notice_type: "offer_completed"
    )
    redirect_to dashboard_path, notice: "Transaction Complete! Item officially sold.", status: :see_other
  end

  def destroy
    unless @offer.withdrawable_by_buyer?(current_user)
      redirect_back fallback_location: @offer.item, alert: "You cannot withdraw this offer right now."
      return
    end

    withdrawn_item = @offer.item
    withdrawn_price = @offer.price
    withdrawn_seller = @offer.seller
    withdrawn_buyer = @offer.buyer

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

    sync_offer_notice_to_conversation(
      item: withdrawn_item,
      buyer: withdrawn_buyer,
      seller: withdrawn_seller,
      actor: current_user,
      notice_type: "offer_withdrawn"
    )

    redirect_back fallback_location: withdrawn_item, notice: "Your offer was withdrawn."
  end

  private

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:price)
  end

  def sync_offer_notice_to_conversation(item:, buyer:, seller:, actor:, notice_type:, amount_hkd: nil)
    conversation = Conversation.find_or_create_by(item:, buyer:, seller:)
    content =
      if %w[offer_created offer_updated].include?(notice_type)
        Message.offer_amount_notice_content(notice_type, amount_hkd)
      else
        Message.offer_status_notice_content(notice_type)
      end

    conversation.messages.create!(user: actor, content: content)
    refresh_offer_value_in_conversation(conversation:, item:, buyer:, seller:)
  end

  def refresh_offer_value_in_conversation(item:, buyer:, seller:, conversation: nil)
    conversation ||= Conversation.find_by(item:, buyer:, seller:)
    return if conversation.blank?

    Turbo::StreamsChannel.broadcast_replace_to(
      conversation,
      target: view_context.dom_id(conversation, :offer_value),
      partial: "conversations/offer_value",
      locals: {
        conversation: conversation,
        offer: Offer.not_declined.find_by(item:, buyer:, seller:)
      }
    )
  end

  def acceptance_error_for(offer, item)
    return "This offer can no longer be accepted." unless offer.pending?
    return "This item is not accepting offers right now." unless item.status == "available" && !item.removed? && !offer.seller&.banned?
    return "Another offer is already in progress for this item." if item.offers.where(status: "accepted").where.not(id: offer.id).exists?

    nil
  end

  def cancellation_error_for(offer, item)
    return "Only accepted transactions can be cancelled." unless offer.accepted?
    return "This item can no longer be updated." if item.removed? || item.status == "sold"

    nil
  end

  def completion_error_for(offer, item)
    return "Only accepted transactions can be completed." unless offer.accepted?
    return "This item can no longer be completed." if item.removed? || item.status == "sold"

    nil
  end
end
