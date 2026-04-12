require "rails_helper"

RSpec.describe "Favorites", type: :request do
  it "adds and removes a favorite for a visible item" do
    seller = create_user(email: "favorite_seller@cuhk.edu.hk")
    buyer = create_user(email: "favorite_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Desk Lamp")

    sign_in buyer

    expect do
      post item_favorite_path(item)
    end.to change(Favorite, :count).by(1)

    expect(response).to redirect_to(item_path(item))
    expect(buyer.reload.favorited_items).to include(item)

    expect do
      delete item_favorite_path(item)
    end.to change(Favorite, :count).by(-1)

    expect(response).to redirect_to(item_path(item))
    expect(buyer.reload.favorited_items).to be_empty
  end

  it "rejects favoriting an item that is no longer visible" do
    seller = create_user(email: "favorite_hidden_seller@cuhk.edu.hk")
    buyer = create_user(email: "favorite_hidden_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Archived Lamp", status: "removed")

    sign_in buyer

    expect do
      post item_favorite_path(item)
    end.not_to change(Favorite, :count)

    expect(response).to redirect_to(items_path)
  end

  it "shows only available favorites on the dashboard" do
    seller = create_user(email: "dashboard_favorite_seller@cuhk.edu.hk")
    buyer = create_user(email: "dashboard_favorite_buyer@cuhk.edu.hk")
    visible_item = create_item(user: seller, title: "Saved Chair")
    removed_item = create_item(user: seller, title: "Removed Chair", status: "removed")

    Favorite.create!(user: buyer, item: visible_item)
    Favorite.create!(user: buyer, item: removed_item)

    sign_in buyer
    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Saved Chair")
    expect(response.body).not_to include("Removed Chair")
  end
end
