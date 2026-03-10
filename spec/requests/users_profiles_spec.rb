require "rails_helper"

RSpec.describe "User profiles", type: :request do
  let!(:college) { College.create!(name: "United College", listing_expiry_days: 30) }
  let!(:seller) do
    User.create!(
      email: "seller@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:viewer) do
    User.create!(
      email: "viewer@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:category) { Category.create!(name: "Electronic") }
  let!(:seller_item) do
    Item.create!(
      title: "Headphones",
      price: 200,
      description: "Noise cancelling",
      status: "available",
      user: seller,
      college: college,
      category: category
    )
  end

  it "shows the seller profile link on the item page" do
    sign_in viewer

    get item_path(seller_item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(user_path(seller))
    expect(response.body).to include(seller.email)
  end

  it "shows the seller items on the profile page" do
    sign_in viewer

    get user_path(seller)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Items by this seller:")
    expect(response.body).to include("Headphones")
  end
end
