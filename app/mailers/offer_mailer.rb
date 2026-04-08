class OfferMailer < ApplicationMailer
  default from: "no-reply@cuhk-marketplace.com"

  # Scenario 1: buyers bid, sellers get notified
  def notify_seller(offer)
    @offer = offer
    @buyer = offer.buyer
    @seller = offer.seller
    @item = offer.item

    mail(to: @seller.email, subject: "New Offer for your #{@item.title}!")
  end

  # Scenario 2: after sellers deal with the offers, buyers get notified
  def notify_buyer(offer)
    @offer = offer
    @buyer = offer.buyer
    @seller = offer.seller
    @item = offer.item

    status_text = @offer.status == "accepted" ? "Accepted 🎉" : "Declined ❌"
    mail(to: @buyer.email, subject: "Your offer for #{@item.title} was #{status_text}")
  end
end
