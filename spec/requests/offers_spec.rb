require "rails_helper"

RSpec.describe "Offers", type: :request do
  let!(:college) { College.create!(name: "Morningside College", listing_expiry_days: 30) }
  let!(:category) { Category.create!(name: "Electronic") }
  let!(:seller) do
    User.create!(
      email: "seller@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:buyer) do
    User.create!(
      email: "buyer@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:item) do
    Item.create!(
      title: "iPad",
      price: 3000,
      description: "Lightly used",
      status: "available",
      user: seller,
      college: college,
      category: category
    )
  end

  describe "creating offers" do
    it "rejects a second create request for the same buyer and item" do
      sign_in buyer
      Offer.create!(price: 2800, buyer: buyer, seller: seller, item: item)

      expect do
        post item_offers_path(item), params: {
          offer: { price: 2850 },
          offer_currency: "HKD"
        }
      end.not_to change(Offer, :count)

      expect(response).to redirect_to(item_path(item))
      expect(flash[:alert]).to include("already have an offer")
    end
  end

  describe "updating offers" do
    it "updates the existing offer instead of creating another one" do
      sign_in buyer
      offer = Offer.create!(price: 2800, buyer: buyer, seller: seller, item: item)

      patch offer_path(offer), params: {
        offer: { price: 2850 },
        offer_currency: "HKD"
      }

      expect(response).to redirect_to(item_path(item))
      expect(offer.reload.price.to_i).to eq(2850)
      expect(item.offers.count).to eq(1)
    end
  end
end
