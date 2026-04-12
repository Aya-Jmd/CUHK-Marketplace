require "rails_helper"

RSpec.describe "Reserved item access", type: :request do
  let!(:college) { create_college(name: "United College") }
  let!(:other_college) { create_college(name: "Shaw College") }
  let!(:seller) { create_user(email: "reserved_seller@cuhk.edu.hk", college:) }
  let!(:buyer) { create_user(email: "reserved_buyer@cuhk.edu.hk", college: other_college) }
  let!(:outsider) { create_user(email: "reserved_outsider@cuhk.edu.hk", college: other_college) }
  let!(:admin) do
    create_user(email: "reserved_admin@cuhk.edu.hk", role: :admin).tap do |user|
      user.update!(setup_completed: true)
    end
  end
  let!(:college_admin) do
    create_user(email: "reserved_college_admin@cuhk.edu.hk", college:, role: :college_admin).tap do |user|
      user.update!(setup_completed: true)
    end
  end
  let!(:item) { create_item(user: seller, college:, title: "Reserved Camera", is_global: true) }
  let!(:accepted_offer) do
    Offer.create!(item:, buyer:, seller:, price: 150, status: "accepted").tap do
      item.update!(status: "pending_dropoff")
    end
  end

  it "blocks outsiders from viewing a reserved item" do
    sign_in outsider

    get item_path(item)

    expect(response).to redirect_to(items_path)
  end

  it "shows the seller-only reserved status card" do
    sign_in seller

    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Reserved for transaction")
    expect(response.body).to include("Your item is currently reserved for a transaction. Check your dashboard.")
    expect(response.body).not_to include("Make an offer")
    expect(response.body).not_to include("Message seller")
    expect(response.body).not_to include("Manage listing")
  end

  it "shows the buyer-only reserved status card" do
    sign_in buyer

    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("This item is reserved for you. Check your dashboard for the transaction PIN.")
    expect(response.body).not_to include("Make an offer")
    expect(response.body).not_to include("Message seller")
  end

  it "shows the admin reserved status and delete controls" do
    sign_in admin

    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(href="#{user_path(seller)}"))
    expect(response.body).to include(%(href="#{user_path(buyer)}"))
    expect(response.body).to include("Manage item")
    expect(response.body).to include("Delete item")
    expect(response.body).not_to include("Edit item")
    expect(response.body).not_to include("Message seller")
  end

  it "shows the same-college admin reserved status and delete controls" do
    sign_in college_admin

    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(href="#{user_path(seller)}"))
    expect(response.body).to include(%(href="#{user_path(buyer)}"))
    expect(response.body).to include("Manage item")
    expect(response.body).to include("Delete item")
  end

  it "blocks the seller from editing a reserved item" do
    sign_in seller

    get edit_item_path(item)

    expect(response).to redirect_to(item_path(item))

    follow_redirect!

    expect(response.body).to include("You can't edit an item involved in a transaction!")
    expect(response.body).not_to include("Update your item")
  end

  it "blocks direct offers and new conversations from outsiders while reserved" do
    sign_in outsider

    expect do
      post item_offers_path(item), params: { offer: { price: 175 }, offer_currency: "HKD" }
    end.not_to change(Offer, :count)

    expect(response).to redirect_to(items_path)

    expect do
      post conversations_path, params: { item_id: item.id, message: { content: "Can I still buy this?" } }
    end.not_to change(Conversation, :count)

    expect(response).to redirect_to(items_path)
  end

  it "hard deletes the item and all related records when an admin deletes it" do
    deletable_item = create_item(user: seller, college:, title: "Reserved Laptop", is_global: true)
    pending_buyer = create_user(email: "reserved_pending_buyer@cuhk.edu.hk", college:)
    final_buyer = create_user(email: "reserved_final_buyer@cuhk.edu.hk", college: other_college)
    pending_offer = Offer.create!(item: deletable_item, buyer: pending_buyer, seller:, price: 125, status: "pending")
    final_offer = Offer.create!(item: deletable_item, buyer: final_buyer, seller:, price: 150, status: "accepted")
    deletable_item.update!(status: "pending_dropoff")
    pending_conversation = Conversation.create!(item: deletable_item, buyer: pending_buyer, seller:)
    final_conversation = Conversation.create!(item: deletable_item, buyer: final_buyer, seller:)
    pending_conversation.messages.create!(user: pending_buyer, content: "Any update?")
    final_conversation.messages.create!(user: seller, content: "Bring your PIN.")
    report = ItemReport.create!(item: deletable_item, reporter: outsider, message: "Please review this listing.")
    Notification.create!(
      recipient: seller,
      actor: admin,
      action: "offer_withdrawn",
      notifiable: deletable_item,
      amount_hkd: 99
    )

    sign_in admin

    delete item_path(deletable_item)

    expect(response).to redirect_to(items_path)
    expect(Item.exists?(deletable_item.id)).to be(false)
    expect(Offer.where(item_id: deletable_item.id)).to be_empty
    expect(Conversation.where(item_id: deletable_item.id)).to be_empty
    expect(Message.where(conversation_id: [ pending_conversation.id, final_conversation.id ])).to be_empty
    expect(ItemReport.where(item_id: deletable_item.id)).to be_empty
    expect(Notification.where(notifiable_type: "Item", notifiable_id: deletable_item.id)).to be_empty
    expect(Notification.where(notifiable_type: "Offer", notifiable_id: [ pending_offer.id, final_offer.id ])).to be_empty
    expect(Notification.where(notifiable_type: "ItemReport", notifiable_id: report.id)).to be_empty

    get item_path(deletable_item.id)

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("The requested item does not exist.")
  end
end
