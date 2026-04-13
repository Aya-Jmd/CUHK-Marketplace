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

  it "does not let a seller favorite their own item" do
    seller = create_user(email: "favorite_own_seller@cuhk.edu.hk")
    item = create_item(user: seller, title: "My Own Lamp")

    sign_in seller

    expect do
      post item_favorite_path(item)
    end.not_to change(Favorite, :count)

    expect(response).to redirect_to(item_path(item))
    expect(flash[:alert]).to eq("You cannot favorite your own item.")
  end

  it "does not render the favorite button on a seller's own item page" do
    seller = create_user(email: "favorite_self_view_seller@cuhk.edu.hk")
    item = create_item(user: seller, title: "Seller Owned Lamp")

    sign_in seller
    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("favorite_button_item_show_item_#{item.id}")
    expect(response.body).not_to include("favorite-toggle")
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

  it "renders the item-page favorite toggle as a turbo stream" do
    seller = create_user(email: "favorite_turbo_seller@cuhk.edu.hk")
    buyer = create_user(email: "favorite_turbo_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Turbo Favorite Lamp")

    sign_in buyer
    post item_favorite_path(item), params: { context: "item_show" }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include("turbo-stream")
    expect(response.body).to include("favorite_button_item_show_item_#{item.id}")
  end

  it "refreshes the dashboard favorites section as a turbo stream" do
    seller = create_user(email: "favorite_dashboard_stream_seller@cuhk.edu.hk")
    buyer = create_user(email: "favorite_dashboard_stream_buyer@cuhk.edu.hk")
    kept_item = create_item(user: seller, title: "Kept Favorite")
    removed_item = create_item(user: seller, title: "Removed Favorite")
    Favorite.create!(user: buyer, item: kept_item)
    Favorite.create!(user: buyer, item: removed_item)

    sign_in buyer
    delete item_favorite_path(removed_item), params: { context: "dashboard_favorites" }, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include("dashboard_favorite_items_section")
    expect(response.body).to include("Kept Favorite")
    expect(response.body).not_to include("Removed Favorite")
  end
end
