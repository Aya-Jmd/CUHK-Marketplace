class OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_offer, only: [ :accept, :decline, :complete, :cancel ]

  def create
    @item = Item.find(params[:item_id])

    if @item.user == current_user
      redirect_to @item, alert: "You cannot make an offer on your own item."
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

  def accept
    return unless current_user == @offer.seller

    if @offer.update(status: "accepted")
      @offer.item.update(status: "pending_dropoff")

      Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_accepted", notifiable: @offer)
      redirect_to profile_path, notice: "Offer accepted! Item reserved. Waiting for the buyer's PIN."
    end
  end

  def decline
    return unless current_user == @offer.seller

    @offer.update(status: "declined")
    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_declined", notifiable: @offer)
    redirect_to profile_path, notice: "Offer declined."
  end

  def cancel
    return unless current_user == @offer.seller

    @offer.update(status: "failed")
    @offer.item.update(status: "available")

    Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_cancelled", notifiable: @offer)
    redirect_to profile_path, alert: "Transaction cancelled. The item is back on the market."
  end

  def complete
    return unless current_user == @offer.seller

    if params[:meetup_code] == @offer.meetup_code
      @offer.update(status: "completed")
      @offer.item.update(status: "sold", sold_at: Time.current)
      @offer.item.offers.where(status: "pending").update_all(status: "declined")

      Notification.create(recipient: @offer.buyer, actor: current_user, action: "offer_completed", notifiable: @offer)
      redirect_to profile_path, notice: "Transaction Complete! Item officially sold.", status: :see_other
    else
      redirect_to profile_path, alert: "Incorrect PIN. Please try again.", status: :see_other
    end
  end

  private

  def set_offer
    @offer = Offer.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(:price)
  end
end
