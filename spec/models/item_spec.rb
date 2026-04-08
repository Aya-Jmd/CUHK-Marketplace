require "rails_helper"

RSpec.describe Item, type: :model do
  it "is valid with required fields" do
    user = create_user(email: "seller_item_spec@cuhk.edu.hk")
    item = create_item(user:, title: "Calculus Textbook", price: 250)

    expect(item).to be_valid
  end

  it "requires title and positive price" do
    user = create_user(email: "seller_item_validation@cuhk.edu.hk")
    item = Item.new(user:, college: user.college, title: nil, price: -10)

    expect(item).not_to be_valid
    expect(item.errors[:title]).to be_present
    expect(item.errors[:price]).to be_present
  end

  it "returns only available items in available scope" do
    user = create_user(email: "scope_seller@cuhk.edu.hk")
    available_item = create_item(user:, title: "Desk Lamp", status: "available")
    create_item(user:, title: "Sold Lamp", status: "sold")

    expect(Item.available).to contain_exactly(available_item)
  end

  it "computes location utility methods" do
    user = create_user(email: "location_seller@cuhk.edu.hk")
    item = create_item(
      user:,
      title: "Drawer",
      latitude: 22.41,
      longitude: 114.21
    )

    expect(item.has_location?).to be(true)
    expect(item.distance_from({ lat: 22.42, lng: 114.20 })).to be_a(Float)
  end
end
