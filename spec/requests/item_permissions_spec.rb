require "rails_helper"

RSpec.describe "Item permissions", type: :request do
  describe "editing another user's item" do
    it "prevents a super admin from opening the edit form for someone else's item" do
      seller = create_user(email: "foreign_item_seller@cuhk.edu.hk")
      admin = create_user(email: "foreign_item_admin@cuhk.edu.hk", role: :admin)
      admin.update!(setup_completed: true)
      item = create_item(user: seller, title: "Protected Listing")

      sign_in admin
      get edit_item_path(item)

      expect(response).to redirect_to(item_path(item))

      follow_redirect!

      expect(response.body).to include("Only the seller can edit this item.")
      expect(response.body).not_to include("Update your item")
    end

    it "prevents a college admin from updating a same-college item they do not own" do
      college = create_college(name: "Shaw College")
      seller = create_user(email: "same_college_seller@cuhk.edu.hk", college:)
      college_admin = create_user(email: "same_college_admin@cuhk.edu.hk", college:, role: :college_admin)
      college_admin.update!(setup_completed: true)
      item = create_item(user: seller, college:, title: "Original Title", is_global: false)

      sign_in college_admin

      expect do
        patch item_path(item), params: { item: { title: "Changed By Admin" } }
      end.not_to change { item.reload.title }

      expect(response).to redirect_to(item_path(item))

      follow_redirect!

      expect(response.body).to include("Only the seller can edit this item.")
    end
  end

  describe "deleting another user's item" do
    it "allows a super admin to delete any item on the marketplace" do
      seller = create_user(email: "marketplace_seller@cuhk.edu.hk")
      admin = create_user(email: "system_admin_delete@cuhk.edu.hk", role: :admin)
      admin.update!(setup_completed: true)
      item = create_item(user: seller, title: "System Admin Removal Target", is_global: false)

      sign_in admin

      expect do
        delete item_path(item)
      end.to change(Item, :count).by(-1)

      expect(response).to redirect_to(items_path)
    end

    it "allows a college admin to delete same-college local and global items" do
      college = create_college(name: "Morningside College")
      seller = create_user(email: "college_scope_seller@cuhk.edu.hk", college:)
      college_admin = create_user(email: "college_scope_admin@cuhk.edu.hk", college:, role: :college_admin)
      college_admin.update!(setup_completed: true)
      local_item = create_item(user: seller, college:, title: "Local Scope Item", is_global: false)
      global_item = create_item(user: seller, college:, title: "Global Scope Item", is_global: true)

      sign_in college_admin

      expect do
        delete item_path(local_item)
      end.to change(Item, :count).by(-1)

      expect(response).to redirect_to(items_path)

      expect do
        delete item_path(global_item)
      end.to change(Item, :count).by(-1)

      expect(response).to redirect_to(items_path)
    end

    it "prevents a college admin from deleting an item from another college" do
      shaw = create_college(name: "Shaw College")
      new_asia = create_college(name: "New Asia College")
      seller = create_user(email: "cross_college_seller@cuhk.edu.hk", college: new_asia)
      college_admin = create_user(email: "cross_college_admin@cuhk.edu.hk", college: shaw, role: :college_admin)
      college_admin.update!(setup_completed: true)
      item = create_item(user: seller, college: new_asia, title: "Off Limits Item")

      sign_in college_admin

      expect do
        delete item_path(item)
      end.not_to change(Item, :count)

      expect(response).to redirect_to(item_path(item))

      follow_redirect!

      expect(response.body).to include("You are not allowed to delete this item.")
    end
  end

  describe "GET /items/:id" do
    it "shows delete-only moderation controls to admins viewing another user's item" do
      seller = create_user(email: "show_page_seller@cuhk.edu.hk")
      admin = create_user(email: "show_page_admin@cuhk.edu.hk", role: :admin)
      admin.update!(setup_completed: true)
      item = create_item(user: seller, title: "Show Page Target")

      sign_in admin
      get item_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Delete item")
      expect(response.body).not_to include("Edit item")
    end
  end
end
