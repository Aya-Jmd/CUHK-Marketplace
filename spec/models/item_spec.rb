require "rails_helper"

RSpec.describe Item, type: :model do
  let!(:college) { College.create!(name: "Chung Chi College", listing_expiry_days: 30) }
  let!(:user) do
    User.create!(
      email: "seller@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:category) { Category.create!(name: "Textbook") }

  subject(:item) do
    described_class.new(
      title: "Calculus Textbook",
      price: 120,
      description: "Used but clean",
      user: user,
      college: college,
      category: category
    )
  end

  it "is valid with the required attributes" do
    expect(item).to be_valid
  end

  it "allows items without a category" do
    item.category = nil

    expect(item).to be_valid
  end

  it "requires a title" do
    item.title = nil

    expect(item).not_to be_valid
    expect(item.errors[:title]).to include("can't be blank")
  end

  it "requires a price" do
    item.price = nil

    expect(item).not_to be_valid
    expect(item.errors[:price]).to include("can't be blank")
  end

  it "requires the price to be greater than zero" do
    item.price = 0

    expect(item).not_to be_valid
    expect(item.errors[:price]).to include("must be greater than 0")
  end

  it "returns only available items from the available scope" do
    available_item = described_class.create!(
      title: "Available Item",
      price: 50,
      description: "Ready to sell",
      status: "available",
      user: user,
      college: college,
      category: category
    )
    described_class.create!(
      title: "Sold Item",
      price: 40,
      description: "Already sold",
      status: "sold",
      user: user,
      college: college,
      category: category
    )

    expect(described_class.available).to contain_exactly(available_item)
  end
end
