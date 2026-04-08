require 'rails_helper'

RSpec.describe Offer, type: :model do
  # These are the rules we established today
  describe "Validations and Callbacks" do
    let(:college) { College.create!(name: "United College", listing_expiry_days: 30) }
    let(:category) { Category.create!(name: "Clothing") }
    let(:buyer) { User.create!(email: "buyer@example.com", password: "password123", password_confirmation: "password123", college: college) }
    let(:seller) { User.create!(email: "seller@example.com", password: "password123", password_confirmation: "password123", college: college) }
    let(:item) { Item.create!(title: "CR7 Boots", price: 67, user: seller, college: college, category: category, status: "available") }

    it "is valid with a price, buyer, and seller" do
      offer = Offer.new(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer).to be_valid
    end

    it "automatically sets a 4-digit meetup code before creation" do
      offer = Offer.create!(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer.meetup_code).to be_present
      expect(offer.meetup_code.length).to eq(4)
    end

    it "defaults to a pending status" do
      offer = Offer.create!(price: 60, buyer: buyer, seller: seller, item: item)
      expect(offer.pending?).to be true
    end

    it "allows one reusable offer per buyer and item" do
      Offer.create!(price: 60, buyer: buyer, seller: seller, item: item)
      duplicate = Offer.new(price: 62, buyer: buyer, seller: seller, item: item)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:buyer_id]).to include("has already been taken")
    end
  end
end
