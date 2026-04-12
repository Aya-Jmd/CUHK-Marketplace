require "rails_helper"

RSpec.describe "Items and Search", type: :request do
  describe "GET /" do
    it "lets guests browse the public marketplace homepage" do
      seller = create_user(email: "guest_root_seller@cuhk.edu.hk")
      create_item(user: seller, title: "Homepage Listing")

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Homepage Listing")
      expect(response).not_to redirect_to(new_user_session_path)
    end
  end

  describe "GET /items" do
    it "allows guests to browse public marketplace listings" do
      seller = create_user(email: "guest_market_seller@cuhk.edu.hk")
      create_item(user: seller, title: "Guest Visible Listing")

      get items_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Guest Visible Listing")
      expect(response.body).to include("Sign up", "Sign in")
      expect(response.body).not_to include("SELL")
    end

    it "shows own college and global items after login" do
      college_a = create_college(name: "Shaw")
      college_b = create_college(name: "New Asia")
      buyer = create_user(email: "buyer_items@cuhk.edu.hk", college: college_a)
      seller_same_college = create_user(email: "same_college_seller@cuhk.edu.hk", college: college_a)
      seller_other_college = create_user(email: "other_college_seller@cuhk.edu.hk", college: college_b)

      visible_local = create_item(user: seller_same_college, title: "Local Desk", is_global: false)
      visible_global = create_item(user: seller_other_college, title: "Global Book", is_global: true)
      hidden_other_college = create_item(user: seller_other_college, title: "Hidden Chair", is_global: false)

      sign_in buyer
      get items_path

      expect(response.body).to include(visible_local.title, visible_global.title)
      expect(response.body).not_to include(hidden_other_college.title)
    end

    it "updates the hero subtitle for the selected college scope" do
      college = create_college(name: "Lee Woo Sing College")
      user = create_user(email: "college_scope_user@cuhk.edu.hk", college:)

      sign_in user
      get items_path, params: { scope: "college" }

      expect(response.body).to include("Buy, sell, and discover everyday student finds across Lee Woo Sing.")
    end
  end

  describe "POST /items" do
    it "rejects asking prices above the HKD cap" do
      seller = create_user(email: "overpriced_item_seller@cuhk.edu.hk")

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "Too Expensive Sofa",
            price: Item::MAX_PRICE_HKD + 1,
            description: "Way too expensive"
          }
        }
      }.not_to change(Item, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("must be less than or equal to #{Item::MAX_PRICE_HKD}")
    end
  end

  describe "GET /items/:id" do
    it "blocks direct access to an out-of-scope local item" do
      shaw = create_college(name: "Shaw")
      new_asia = create_college(name: "New Asia")
      viewer = create_user(email: "hidden_item_viewer@cuhk.edu.hk", college: shaw)
      seller = create_user(email: "hidden_item_seller@cuhk.edu.hk", college: new_asia)
      item = create_item(user: seller, title: "Hidden Rice Cooker", college: new_asia, is_global: false)

      sign_in viewer
      get item_path(item)

      expect(response).to redirect_to(items_path)

      follow_redirect!

      expect(response.body).to include("This item is not available.")
    end

    it "hides seller sidebar cards when the seller views their own item" do
      seller = create_user(email: "owner_show@cuhk.edu.hk")
      item = create_item(user: seller, title: "Owner Item")

      sign_in seller
      get item_path(item)

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.css(".item-show__seller-card")).to be_empty
      expect(response.body).not_to include("You are the seller")
    end

    it "does not render a login button inside the distance card for guests" do
      seller = create_user(email: "distance_seller@cuhk.edu.hk")
      item = create_item(user: seller, title: "Distance Item", latitude: 22.4196, longitude: 114.2068)

      get item_path(item)

      document = Nokogiri::HTML.parse(response.body)
      distance_card = document.at_css(".item-show__distance-card")

      expect(response).to have_http_status(:ok)
      expect(distance_card).to be_present
      expect(distance_card.text).to include("Sign in to see distance")
      expect(distance_card.css("a").map(&:text)).not_to include("Log in")
    end

    it "replaces sold item sidebar actions with a status card" do
      college = create_college(name: "United College")
      seller = create_user(email: "sold_item_seller@cuhk.edu.hk", college:)
      viewer = create_user(email: "sold_item_viewer@cuhk.edu.hk", college:)
      item = create_item(user: seller, title: "Sold Watch", college:, status: "sold")

      sign_in viewer
      get item_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Item status")
      expect(response.body).to include("This item has been sold")
      expect(response.body).not_to include("Make an offer")
      expect(response.body).not_to include("Update your offer")
      expect(response.body).not_to include("Message seller")
      expect(response.body).not_to include("Distance")
      expect(response.body).not_to include("Manage item")
    end

    it "shows an estimated walk in the pickup area for signed-in users with a saved location" do
      seller = create_user(email: "pickup_walk_seller@cuhk.edu.hk")
      buyer = create_user(email: "pickup_walk_buyer@cuhk.edu.hk")
      buyer.update!(default_location: "campus_central", latitude: 22.4172, longitude: 114.2071)
      item = create_item(user: seller, title: "Pickup Walk Item", latitude: 22.4180, longitude: 114.2068)

      sign_in buyer
      get item_path(item)

      document = Nokogiri::HTML.parse(response.body)
      pickup_travel = document.at_css(".item-show__pickup-travel")

      expect(response).to have_http_status(:ok)
      expect(pickup_travel).to be_present
      expect(pickup_travel.text).to include("Walk from your default location")
      expect(pickup_travel.text).to match(/\d+\.\d{2}\s*km/)
      expect(pickup_travel.text).to match(/About \d+ min on foot/)
    end
  end

  describe "GET /search" do
    it "allows guests to use search" do
      seller = create_user(email: "guest_search_seller@cuhk.edu.hk")
      category = Category.create!(name: "Guest Search Category")
      create_item(user: seller, title: "Guest Search Result", category:)

      get search_path, params: { q: "guest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Guest Search Result")
    end

    it "filters by keyword and category" do
      college = create_college(name: "Shaw")
      buyer = create_user(email: "searcher@cuhk.edu.hk", college:)
      seller = create_user(email: "search_seller@cuhk.edu.hk", college:)
      math = Category.create!(name: "Math")
      electronics = Category.create!(name: "Electronics")
      matching = create_item(user: seller, title: "Calculus Textbook", category: math)
      non_matching = create_item(user: seller, title: "Phone Charger", category: electronics)

      sign_in buyer
      get search_path, params: { q: "calc", category_id: math.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(matching.title)
      expect(response.body).not_to include(non_matching.title)
    end

    it "renders the custom filter sidebar scrollbar shell" do
      college = create_college(name: "New Asia")
      buyer = create_user(email: "search_sidebar@cuhk.edu.hk", college:)
      seller = create_user(email: "search_sidebar_seller@cuhk.edu.hk", college:)
      category = Category.create!(name: "Books")
      create_item(user: seller, title: "Montegrappa Fountain Pen", category:)

      sign_in buyer
      get search_path, params: { category_id: category.id }

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css(".search-results-page__sidebar-card[data-controller='filter-state custom-scrollbar']")).to be_present
      expect(document.at_css(".search-results-page__sidebar-scroll[data-custom-scrollbar-target='viewport']")).to be_present
      expect(document.at_css(".search-results-page__custom-scrollbar[data-custom-scrollbar-target='track']")).to be_present
      expect(document.at_css(".search-results-page__custom-scrollbar-thumb[data-custom-scrollbar-target='thumb']")).to be_present
    end
  end
end
