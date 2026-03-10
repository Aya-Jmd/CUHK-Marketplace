require "rails_helper"

RSpec.describe "Search", type: :request do
  let!(:college) { College.create!(name: "New Asia College", listing_expiry_days: 30) }
  let!(:user) do
    User.create!(
      email: "buyer@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:textbook_category) { Category.create!(name: "Textbook") }
  let!(:book_category) { Category.create!(name: "Book") }
  let!(:matching_item) do
    Item.create!(
      title: "Z-book pro",
      price: 100,
      description: "Graphing calculator",
      status: "available",
      user: user,
      college: college,
      category: textbook_category
    )
  end
  let!(:non_matching_item) do
    Item.create!(
      title: "Linear Algebra Notes",
      price: 25,
      description: "Printed notes",
      status: "available",
      user: user,
      college: college,
      category: book_category
    )
  end
  let!(:sold_item) do
    Item.create!(
      title: "Z-book sold",
      price: 50,
      description: "Already gone",
      status: "sold",
      user: user,
      college: college,
      category: textbook_category
    )
  end

  it "returns only matching available items" do
    sign_in user

    get search_path, params: { q: "z-book", scope: "all" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Z-book pro")
    expect(response.body).not_to include("Linear Algebra Notes")
    expect(response.body).not_to include("Z-book sold")
  end
end
