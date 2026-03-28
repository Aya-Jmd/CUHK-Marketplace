class OffersController < ApplicationController
  # Security: Must be logged in to make an offer!
  before_action :authenticate_user!

  def create
    @item = Item.find(params[:item_id])
    
    # Security: Prevent the seller from making an offer on their own item
    if @item.user == current_user
      redirect_to @item, alert: "You cannot make an offer on your own item."
      return
    end

    # Build the offer in memory
    @offer = @item.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.seller = @item.user

    # Save to database and alert the user
    if @offer.save
      redirect_to @item, notice: "Success! Your offer of HK$#{@offer.price} was sent to the seller."
    else
      redirect_to @item, alert: "Failed to send offer. Make sure you entered a valid price."
    end
  end

  def update
    @offer = Offer.find(params[:id])
    
    # Security: Kick them out if they aren't the seller!
    unless current_user == @offer.seller
      redirect_to dashboard_path, alert: "You are not authorized to do that."
      return
    end

    if params[:status] == "accepted"
      @offer.update(status: "accepted")
      @offer.item.update(status: "pending_dropoff") # Removes it from the marketplace!
      redirect_to dashboard_path, notice: "Offer accepted! The item is now locked for dropoff."
      
    elsif params[:status] == "declined"
      @offer.update(status: "declined")
      redirect_to dashboard_path, notice: "Offer declined."
      
    elsif params[:status] == "completed"
      if params[:meetup_code] == @offer.meetup_code
        @offer.update(status: "completed")
        @offer.item.update(status: "sold", sold_at: Time.current)
        @offer.item.offers.where(status: "pending").update_all(status: "declined")

        # Added status: :see_other for Turbo!
        redirect_to dashboard_path, notice: "Transaction Complete! The PIN matched and the item is officially sold.", status: :see_other
      else
        # Added status: :see_other for Turbo!
        redirect_to dashboard_path, alert: "Incorrect PIN. Please try again.", status: :see_other
      end

    elsif params[:status] == "failed"
      # If the buyer ghosts them, cancel the transaction and relist the item!
      @offer.update(status: "failed")
      @offer.item.update(status: "available")
      redirect_to dashboard_path, alert: "Transaction cancelled. The item is back on the market."
    end
  end

  private

  def offer_params
    params.require(:offer).permit(:price)
  end
end