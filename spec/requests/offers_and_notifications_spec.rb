require "rails_helper"

RSpec.describe "Offers and Notifications", type: :request do
  it "creates offer and notification for seller" do
    seller = create_user(email: "request_offer_seller@cuhk.edu.hk")
    buyer = create_user(email: "request_offer_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Physics Book")

    sign_in buyer
    post item_offers_path(item), params: { offer: { price: 130 }, offer_currency: "HKD" }

    expect(response).to redirect_to(item_path(item))
    expect(item.offers.count).to eq(1)
    expect(Notification.where(recipient: seller, action: "offer_created")).to exist
  end

  it "completes transaction with correct meetup code" do
    seller = create_user(email: "request_complete_seller@cuhk.edu.hk")
    buyer = create_user(email: "request_complete_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Keyboard")
    offer = Offer.create!(item:, buyer:, seller:, price: 200, status: "accepted")
    offer.update_column(:meetup_code, "1234")
    Offer.create!(item:, buyer: create_user(email: "other_buyer@cuhk.edu.hk"), seller:, price: 180, status: "pending")

    sign_in seller
    patch complete_offer_path(offer), params: { meetup_code: "1234" }

    expect(response).to redirect_to(dashboard_path)
    expect(offer.reload.status).to eq("completed")
    expect(item.reload.status).to eq("sold")
    expect(item.offers.where(status: "pending")).to be_empty
  end

  it "marks all unread notifications as read" do
    seller = create_user(email: "notification_owner@cuhk.edu.hk")
    buyer = create_user(email: "notification_actor@cuhk.edu.hk")
    item = create_item(user: seller, title: "Lamp")
    offer = Offer.create!(item:, buyer:, seller:, price: 90)
    Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")
    Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_declined")

    sign_in seller
    patch mark_all_as_read_notifications_path

    expect(response).to redirect_to(notifications_path(category: "all", show_unread: "1"))
    expect(seller.notifications.unread.count).to eq(0)
  end
end
