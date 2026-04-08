require "rails_helper"

RSpec.describe "Items and Search", type: :request do
  describe "GET /items" do
    it "requires login because of ApplicationController guard" do
      get items_path

      expect(response).to redirect_to(new_user_session_path)
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
  end

  describe "GET /search" do
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
  end
end
