require "rails_helper"

RSpec.describe "Items management", type: :request do
  let!(:college) { College.create!(name: "Chung Chi College", listing_expiry_days: 30) }
  let!(:category) { Category.create!(name: "Textbook") }
  let!(:owner) do
    User.create!(
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:other_user) do
    User.create!(
      email: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:item) do
    Item.create!(
      title: "Old Calculator",
      price: 80,
      description: "Works well",
      status: "available",
      user: owner,
      college: college,
      category: category
    )
  end

  describe "creating an item" do
    it "creates an item for the signed-in user" do
      sign_in owner

      expect do
        post items_path, params: {
          item: {
            title: "Calculus Notes",
            price: 35,
            description: "Semester 1 notes",
            category_id: category.id
          }
        }
      end.to change(Item, :count).by(1)

      created_item = Item.order(:created_at).last
      expect(response).to redirect_to(item_url(created_item))
      expect(created_item.user).to eq(owner)
      expect(created_item.college).to eq(owner.college)
      expect(created_item.category).to eq(category)
    end
  end

  describe "editing your own item" do
    it "updates the item" do
      sign_in owner

      patch item_path(item), params: {
        item: {
          title: "Updated Calculator",
          price: 90
        }
      }

      expect(response).to redirect_to(item_path(item))
      expect(item.reload.title).to eq("Updated Calculator")
      expect(item.price).to eq(90)
    end
  end

  describe "deleting your own item" do
    it "destroys the item" do
      sign_in owner

      expect do
        delete item_path(item)
      end.to change(Item, :count).by(-1)

      expect(response).to redirect_to(items_path)
    end
  end

  describe "trying to edit another user's item" do
    it "does not allow access to the edit page" do
      sign_in other_user

      get edit_item_path(item)

      expect(response).to redirect_to(item_path(item))
      follow_redirect!
    end

    it "does not allow updating the item" do
      sign_in other_user

      patch item_path(item), params: {
        item: {
          title: "Hacked Title"
        }
      }

      expect(response).to redirect_to(item_path(item))
      expect(item.reload.title).to eq("Old Calculator")
    end
  end
end
