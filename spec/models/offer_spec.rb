require "rails_helper"

RSpec.describe Offer, type: :model do
  it "generates meetup code and notifies seller on creation" do
    seller = create_user(email: "offer_seller@cuhk.edu.hk")
    buyer = create_user(email: "offer_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "iPad Case")

    offer = Offer.create!(item:, buyer:, seller:, price: 120, status: "pending")

    expect(offer.meetup_code).to match(/\A\d{4}\z/)
    expect(Notification.where(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")).to exist
  end

  it "rejects self-offers" do
    seller = create_user(email: "self_offer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Calculator")

    offer = Offer.new(item:, buyer: seller, seller:, price: 80, status: "pending")

    expect(offer).not_to be_valid
    expect(offer.errors[:buyer]).to include("cannot make an offer on their own item")
    expect(Notification.where(recipient: seller, action: "offer_created")).to be_empty
  end

  it "requires a positive offer price" do
    seller = create_user(email: "offer_validation_seller@cuhk.edu.hk")
    buyer = create_user(email: "offer_validation_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Chair")
    offer = Offer.new(item:, buyer:, seller:, price: 0)

    expect(offer).not_to be_valid
  end
end
