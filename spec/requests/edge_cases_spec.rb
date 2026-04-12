require "rails_helper"

RSpec.describe "Edge Case Guards", type: :request do
  it "prevents buyers from accepting offers they do not own as seller" do
    seller = create_user(email: "edge_seller@cuhk.edu.hk")
    buyer = create_user(email: "edge_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Edge Desk")
    offer = Offer.create!(item:, buyer:, seller:, price: 120, status: "pending")

    sign_in buyer
    patch accept_offer_path(offer)

    expect(offer.reload.status).to eq("pending")
    expect(item.reload.status).to eq("available")
  end

  it "keeps offer accepted when seller enters wrong meetup code" do
    seller = create_user(email: "pin_seller@cuhk.edu.hk")
    buyer = create_user(email: "pin_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Edge Lamp")
    offer = Offer.create!(item:, buyer:, seller:, price: 90, status: "accepted")
    offer.update_column(:meetup_code, "1234")

    sign_in seller
    patch complete_offer_path(offer), params: { meetup_code: "9999" }

    expect(response).to redirect_to(dashboard_path)
    expect(offer.reload.status).to eq("accepted")
    expect(item.reload.status).to eq("available")
  end

  it "prevents completing an offer that has not been accepted" do
    seller = create_user(email: "pending_complete_seller@cuhk.edu.hk")
    buyer = create_user(email: "pending_complete_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Pending Sale")
    offer = Offer.create!(item:, buyer:, seller:, price: 90, status: "pending")
    offer.update_column(:meetup_code, "1234")

    sign_in seller
    patch complete_offer_path(offer), params: { meetup_code: "1234" }

    expect(response).to redirect_to(dashboard_path)
    expect(offer.reload.status).to eq("pending")
    expect(item.reload.status).to eq("available")
  end

  it "prevents accepting a second offer once another offer is already accepted" do
    seller = create_user(email: "second_accept_seller@cuhk.edu.hk")
    first_buyer = create_user(email: "second_accept_buyer1@cuhk.edu.hk")
    second_buyer = create_user(email: "second_accept_buyer2@cuhk.edu.hk")
    item = create_item(user: seller, title: "Single Winner")
    first_offer = Offer.create!(item:, buyer: first_buyer, seller:, price: 100, status: "accepted")
    second_offer = Offer.create!(item:, buyer: second_buyer, seller:, price: 110, status: "pending")
    item.update!(status: "pending_dropoff")

    sign_in seller
    patch accept_offer_path(second_offer)

    expect(response).to redirect_to(dashboard_path)
    expect(first_offer.reload.status).to eq("accepted")
    expect(second_offer.reload.status).to eq("pending")
    expect(item.reload.status).to eq("pending_dropoff")
  end

  it "rejects meetup codes that are not exactly four digits" do
    seller = create_user(email: "pin_format_seller@cuhk.edu.hk")
    buyer = create_user(email: "pin_format_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Desk Lamp")
    offer = Offer.create!(item:, buyer:, seller:, price: 90, status: "accepted")
    offer.update_column(:meetup_code, "1234")

    sign_in seller
    patch complete_offer_path(offer), params: { meetup_code: "12a4" }

    expect(response).to redirect_to(dashboard_path)
    expect(offer.reload.status).to eq("accepted")
    expect(item.reload.status).to eq("available")
  end

  it "blocks conversation creation with empty first message" do
    seller = create_user(email: "chat_guard_seller@cuhk.edu.hk")
    buyer = create_user(email: "chat_guard_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Guard Chair")

    sign_in buyer
    post conversations_path, params: { item_id: item.id, message: { content: "   " } }

    expect(response).to redirect_to(item_path(item))
    expect(Conversation.where(item:, buyer:, seller:)).to be_empty
  end

  it "returns to inbox with alert for empty message in existing conversation" do
    seller = create_user(email: "msg_guard_seller@cuhk.edu.hk")
    buyer = create_user(email: "msg_guard_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Guard Router")
    conversation = Conversation.create!(item:, buyer:, seller:)

    sign_in buyer
    post conversation_messages_path(conversation), params: { message: { content: "" } }

    expect(response).to redirect_to(conversations_path(conversation_id: conversation.id))
    expect(conversation.messages).to be_empty
  end

  it "returns 404 not-found page if user marks another user's notification as read" do
    seller = create_user(email: "notif_owner@cuhk.edu.hk")
    outsider = create_user(email: "notif_outsider@cuhk.edu.hk")
    buyer = create_user(email: "notif_actor_user@cuhk.edu.hk")
    item = create_item(user: seller, title: "Guard Fan")
    offer = Offer.create!(item:, buyer:, seller:, price: 70, status: "pending")
    notification = Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")

    sign_in outsider
    patch mark_as_read_notification_path(notification)

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("The requested data does not exist.")
  end

  it "blocks offers on an out-of-scope local item" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    seller = create_user(email: "hidden_offer_seller@cuhk.edu.hk", college: new_asia)
    buyer = create_user(email: "hidden_offer_buyer@cuhk.edu.hk", college: shaw)
    item = create_item(user: seller, title: "Hidden Offer Item", college: new_asia, is_global: false)

    sign_in buyer

    expect do
      post item_offers_path(item), params: { offer: { price: 120 }, offer_currency: "HKD" }
    end.not_to change(Offer, :count)

    expect(response).to redirect_to(items_path)
  end

  it "blocks conversation creation on an out-of-scope local item" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    seller = create_user(email: "hidden_chat_seller@cuhk.edu.hk", college: new_asia)
    buyer = create_user(email: "hidden_chat_buyer@cuhk.edu.hk", college: shaw)
    item = create_item(user: seller, title: "Hidden Chat Item", college: new_asia, is_global: false)

    sign_in buyer

    expect do
      post conversations_path, params: { item_id: item.id, message: { content: "Can we meet?" } }
    end.not_to change(Conversation, :count)

    expect(response).to redirect_to(items_path)
  end

  it "blocks reporting on an out-of-scope local item" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    seller = create_user(email: "hidden_report_seller@cuhk.edu.hk", college: new_asia)
    buyer = create_user(email: "hidden_report_buyer@cuhk.edu.hk", college: shaw)
    item = create_item(user: seller, title: "Hidden Report Item", college: new_asia, is_global: false)

    sign_in buyer

    expect do
      post item_item_reports_path(item), params: { item_report: { message: "Out of scope report attempt" } }
    end.not_to change(ItemReport, :count)

    expect(response).to redirect_to(items_path)
  end
end
