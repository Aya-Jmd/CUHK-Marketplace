require 'rails_helper'

RSpec.describe Offer, type: :model do
  # These are the rules we established today
  describe "Validations and Callbacks" do
    let(:buyer) { User.create(email: "buyer@example.com", password: "password") }
    let(:seller) { User.create(email: "seller@example.com", password: "password") }
    let(:item) { Item.create(title: "CR7 Boots", price: 67, user: seller, status: "available") }

    it "is valid with a price, buyer, and seller" do
      offer = Offer.new(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer).to be_valid
    end

    it "automatically sets a 4-digit meetup code before creation" do
      offer = Offer.create(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer.meetup_code).to be_present
      expect(offer.meetup_code.length).to eq(4)
    end

    it "defaults to a pending status" do
      offer = Offer.create(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer.pending?).to be true
    end
  end
end
