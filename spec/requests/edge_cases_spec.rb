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
end
