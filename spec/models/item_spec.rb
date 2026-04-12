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

  it "rejects prices above the HKD maximum" do
    user = create_user(email: "seller_item_max_price@cuhk.edu.hk")
    item = Item.new(user:, college: user.college, title: "Luxury Chair", price: Item::MAX_PRICE_HKD + 1)

    expect(item).not_to be_valid
    expect(item.errors[:price]).to include("must be less than or equal to #{Item::MAX_PRICE_HKD}")
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

  it "estimates a walking distance from a user location" do
    user = create_user(email: "walking_distance_seller@cuhk.edu.hk")
    item = create_item(
      user:,
      title: "Campus Fan",
      latitude: 22.4180,
      longitude: 114.2068
    )

    user_location = { lat: 22.4172, lng: 114.2071 }

    expect(item.walking_distance_from(user_location)).to be > item.distance_from(user_location)
  end

  it "restricts local visibility to the same college, owner, and admins" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    seller = create_user(email: "tenancy_seller@cuhk.edu.hk", college: new_asia)
    same_college_buyer = create_user(email: "same_college_viewer@cuhk.edu.hk", college: new_asia)
    other_college_buyer = create_user(email: "other_college_viewer@cuhk.edu.hk", college: shaw)
    admin = create_user(email: "tenancy_admin@cuhk.edu.hk", role: :admin)
    item = create_item(user: seller, title: "Hidden Local Listing", college: new_asia, is_global: false)

    expect(item.visible_to?(seller)).to be(true)
    expect(item.visible_to?(same_college_buyer)).to be(true)
    expect(item.visible_to?(other_college_buyer)).to be(false)
    expect(item.visible_to?(admin)).to be(true)
    expect(item.visible_to?(nil)).to be(false)
  end
end
