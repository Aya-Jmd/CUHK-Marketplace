class OffersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_offer, only: [:accept, :decline, :complete, :cancel]

  def create
    @item = Item.find(params[:item_id])
    
    if @item.user == current_user
      redirect_to @item, alert: "You cannot make an offer on your own item."
      return
    end

    @offer = @item.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.seller = @item.user

    if @offer.save
      Notification.create(recipient: @offer.seller, actor: current_user, action: "made an offer on", notifiable: @offer)
      redirect_to @item, notice: "Success! Your offer of HK$#{@offer.price.to_i} was sent."
    else
      redirect_to @item, alert: "Failed to send offer. Ensure the price is valid."
    end
  end

  def accept
    return unless current_user == @offer.seller

    if @offer.update(status: "accepted")
      @offer.item.update(status: "pending_dropoff") 
      
      Notification.create(recipient: @offer.buyer, actor: current_user, action: "accepted your offer for", notifiable: @offer)
      # CHANGED: Redirects to their dashboard
      redirect_to current_user, notice: "Offer accepted! Item reserved. Waiting for the buyer's PIN."
    end
  end

  def decline
    return unless current_user == @offer.seller

    @offer.update(status: "declined")
    Notification.create(recipient: @offer.buyer, actor: current_user, action: "declined your offer for", notifiable: @offer)
    # CHANGED: Redirects to their dashboard
    redirect_to current_user, notice: "Offer declined."
  end

  def cancel
    return unless current_user == @offer.seller

    @offer.update(status: "failed")
    @offer.item.update(status: "available") 

    Notification.create(recipient: @offer.buyer, actor: current_user, action: "cancelled the transaction for", notifiable: @offer)
    # CHANGED: Redirects to their dashboard
    redirect_to current_user, alert: "Transaction cancelled. The item is back on the market."
  end

  def complete
    return unless current_user == @offer.seller

    if params[:meetup_code] == @offer.meetup_code
      @offer.update(status: "completed")
      @offer.item.update(status: "sold", sold_at: Time.current)
      @offer.item.offers.where(status: "pending").update_all(status: "declined")
      
      Notification.create(recipient: @offer.buyer, actor: current_user, action: "confirmed the sale of", notifiable: @offer)
      # CHANGED: Redirects to their dashboard
      redirect_to current_user, notice: "Transaction Complete! Item officially sold.", status: :see_other
    else
      # CHANGED: Redirects to their dashboard
      redirect_to current_user, alert: "Incorrect PIN. Please try again.", status: :see_other
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