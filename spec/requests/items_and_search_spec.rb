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
    it "uses the seller's saved default location when no pickup point is submitted" do
      seller = create_user(email: "default_pickup_seller@cuhk.edu.hk")
      seller.update!(default_location: "new_asia", latitude: 22.4191, longitude: 114.2094)

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "Default Pickup Chair",
            price: 120,
            description: "Pickup should inherit from the profile."
          }
        }
      }.to change(Item, :count).by(1)

      item = Item.order(:id).last

      expect(item.location_name).to eq("new_asia")
      expect(item.latitude).to eq(22.4191)
      expect(item.longitude).to eq(114.2094)
    end

    it "keeps the submitted pickup point instead of overwriting it with the profile default" do
      seller = create_user(email: "explicit_pickup_seller@cuhk.edu.hk")
      seller.update!(default_location: "new_asia", latitude: 22.4191, longitude: 114.2094)

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "Custom Pickup Chair",
            price: 120,
            description: "Pickup should stay custom.",
            location_name: "shaw",
            latitude: 22.4222,
            longitude: 114.2009
          }
        }
      }.to change(Item, :count).by(1)

      item = Item.order(:id).last

      expect(item.location_name).to eq("shaw")
      expect(item.latitude).to eq(22.4222)
      expect(item.longitude).to eq(114.2009)
    end

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

    it "shows the college price cap notice when the submitted price is too high" do
      college = create_college(name: "Price Rule College")
      college.update!(max_item_price: 80)
      seller = create_user(email: "college_price_rule_seller@cuhk.edu.hk", college:)

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "Too Expensive Lamp",
            price: 81,
            description: "Above the local cap"
          }
        }
      }.not_to change(Item, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      document = Nokogiri::HTML.parse(response.body)

      expect(document.text).to include("Your item's price is too high! It should be lower than HK$80.00.")
    end

    it "rejects titles longer than the maximum length when creating an item" do
      seller = create_user(email: "long_title_create_seller@cuhk.edu.hk")

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "a" * (Item::MAX_TITLE_LENGTH + 1),
            price: 120,
            description: "Too long title"
          }
        }
      }.not_to change(Item, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Title is too long (maximum is #{Item::MAX_TITLE_LENGTH} characters)")
    end

    it "blocks direct item creation once the college posting limit is reached" do
      college = create_college(name: "Posting Limit College")
      college.update!(max_items_per_user: 1)
      seller = create_user(email: "posting_limit_direct_seller@cuhk.edu.hk", college:)
      create_item(user: seller, college:, title: "Existing Listing")

      sign_in seller

      expect {
        post items_path, params: {
          item: {
            title: "Blocked Listing",
            price: 20,
            description: "Should not be created"
          }
        }
      }.not_to change(Item, :count)

      expect(response).to redirect_to(items_path)
      follow_redirect!
      expect(response.body).to include("You already posted the maximum number of items!")
    end
  end

  describe "GET /items/new" do
    it "prefills the sell form with the user's saved default location" do
      seller = create_user(email: "prefilled_sell_form@cuhk.edu.hk")
      seller.update!(default_location: "library", latitude: 22.4188, longitude: 114.2078)

      sign_in seller
      get new_item_path

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css("input[name='item[latitude]']")["value"]).to eq("22.4188")
      expect(document.at_css("input[name='item[longitude]']")["value"]).to eq("114.2078")
      expect(document.at_css("input[name='item[location_name]']")["value"]).to eq("library")
    end

    it "blocks access to the sell page once the college posting limit is reached" do
      college = create_college(name: "Sell Gate College")
      college.update!(max_items_per_user: 1)
      seller = create_user(email: "sell_gate_seller@cuhk.edu.hk", college:)
      create_item(user: seller, college:, title: "Existing Sell Gate Listing")

      sign_in seller
      get new_item_path

      expect(response).to redirect_to(items_path)

      follow_redirect!

      expect(response.body).to include("You already posted the maximum number of items!")
    end
  end

  describe "GET /items/:id/edit" do
    it "prefills the edit form with the user's saved default location when the item has none" do
      seller = create_user(email: "prefilled_edit_form@cuhk.edu.hk")
      seller.update!(default_location: "library", latitude: 22.4188, longitude: 114.2078)
      item = create_item(user: seller, title: "Edit Pickup Item", latitude: nil, longitude: nil)

      sign_in seller
      get edit_item_path(item)

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css("input[name='item[latitude]']")["value"]).to eq("22.4188")
      expect(document.at_css("input[name='item[longitude]']")["value"]).to eq("114.2078")
      expect(document.at_css("input[name='item[location_name]']")["value"]).to eq("library")
    end
  end

  describe "PATCH /items/:id" do
    it "uses the seller's saved default location when updating an item without a pickup point" do
      seller = create_user(email: "default_pickup_update_seller@cuhk.edu.hk")
      seller.update!(default_location: "new_asia", latitude: 22.4191, longitude: 114.2094)
      item = create_item(user: seller, title: "Pickup Update Chair", latitude: nil, longitude: nil)

      sign_in seller
      patch item_path(item), params: {
        item: {
          title: "Pickup Update Chair",
          price: 120,
          description: "Updated without choosing a pickup point.",
          location_name: "",
          latitude: "",
          longitude: ""
        }
      }

      item.reload

      expect(response).to redirect_to(item_path(item))
      expect(item.location_name).to eq("new_asia")
      expect(item.latitude).to eq(22.4191)
      expect(item.longitude).to eq(114.2094)
    end

    it "keeps the submitted pickup point when updating an item" do
      seller = create_user(email: "explicit_pickup_update_seller@cuhk.edu.hk")
      seller.update!(default_location: "new_asia", latitude: 22.4191, longitude: 114.2094)
      item = create_item(user: seller, title: "Custom Update Chair", latitude: nil, longitude: nil)

      sign_in seller
      patch item_path(item), params: {
        item: {
          title: "Custom Update Chair",
          price: 120,
          description: "Updated with a custom pickup point.",
          location_name: "shaw",
          latitude: 22.4222,
          longitude: 114.2009
        }
      }

      item.reload

      expect(response).to redirect_to(item_path(item))
      expect(item.location_name).to eq("shaw")
      expect(item.latitude).to eq(22.4222)
      expect(item.longitude).to eq(114.2009)
    end

    it "rejects titles longer than the maximum length when updating an item" do
      seller = create_user(email: "long_title_update_seller@cuhk.edu.hk")
      item = create_item(user: seller, title: "Original Title")

      sign_in seller

      expect do
        patch item_path(item), params: {
          item: {
            title: "a" * (Item::MAX_TITLE_LENGTH + 1),
            price: 120,
            description: "Updated description"
          }
        }
      end.not_to change { item.reload.title }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Title is too long (maximum is #{Item::MAX_TITLE_LENGTH} characters)")
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

    it "builds price slider steps from the current category scope instead of the global max" do
      college = create_college(name: "Morningside")
      buyer = create_user(email: "search_price_scope@cuhk.edu.hk", college:)
      seller = create_user(email: "search_price_scope_seller@cuhk.edu.hk", college:)
      books = Category.create!(name: "Scoped Books")
      electronics = Category.create!(name: "Scoped Electronics")

      create_item(user: seller, title: "Book A", category: books, price: 12)
      create_item(user: seller, title: "Book B", category: books, price: 20)
      create_item(user: seller, title: "Luxury Server Rack", category: electronics, price: 8_000_000)

      sign_in buyer
      get search_path, params: { category_id: books.id }

      document = Nokogiri::HTML.parse(response.body)
      slider = document.at_css("[data-controller='range-slider']")

      expect(response).to have_http_status(:ok)
      expect(slider).to be_present
      expect(slider["data-range-slider-max-value"].to_f).to eq(20.0)
      expect(JSON.parse(slider["data-range-slider-steps-value"])).to eq([0.0, 12.0, 20.0])
    end

    it "preserves decimal price steps for the slider instead of rounding them up" do
      college = create_college(name: "S.H. Ho")
      buyer = create_user(email: "search_decimal_steps@cuhk.edu.hk", college:)
      seller = create_user(email: "search_decimal_step_seller@cuhk.edu.hk", college:)
      books = Category.create!(name: "Decimal Books")

      create_item(user: seller, title: "Annotated Notes", category: books, price: 124.9)
      create_item(user: seller, title: "Bound Past Papers", category: books, price: 200)

      sign_in buyer
      get search_path, params: { category_id: books.id }

      document = Nokogiri::HTML.parse(response.body)
      slider = document.at_css("[data-controller='range-slider']")

      expect(response).to have_http_status(:ok)
      expect(slider).to be_present
      expect(JSON.parse(slider["data-range-slider-steps-value"])).to eq([0.0, 124.9, 200.0])
    end

    it "filters search results with exact decimal price values" do
      college = create_college(name: "Chung Chi")
      buyer = create_user(email: "search_decimal_filter@cuhk.edu.hk", college:)
      seller = create_user(email: "search_decimal_filter_seller@cuhk.edu.hk", college:)
      books = Category.create!(name: "Decimal Filter Books")
      rounded_down = create_item(user: seller, title: "Workbook 124.89", category: books, price: 124.89)
      exact_match = create_item(user: seller, title: "Workbook 124.90", category: books, price: 124.9)
      upper_bound = create_item(user: seller, title: "Workbook 200.00", category: books, price: 200)

      sign_in buyer
      get search_path, params: {
        category_id: books.id,
        min_price: "124.90",
        max_price: "200.00",
        price_currency: Currency::BASE_CODE
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(rounded_down.title)
      expect(response.body).to include(exact_match.title, upper_bound.title)
    end
  end
end
