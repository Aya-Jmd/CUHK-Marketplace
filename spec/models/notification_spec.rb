require "rails_helper"

RSpec.describe Notification, type: :model do
  it "lists unread notifications via scope" do
    seller = create_user(email: "notif_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Fan")
    offer = Offer.create!(item:, buyer:, seller:, price: 55, status: "pending")
    unread = Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")
    Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_accepted", read_at: Time.current)

    expect(Notification.unread).to include(unread)
    expect(Notification.unread.where(recipient: seller).count).to be >= 1
  end

  it "broadcasts a live notification payload to the recipient stream" do
    recipient = create_user(email: "live_notif_recipient@cuhk.edu.hk")
    actor = create_user(email: "live_notif_actor@cuhk.edu.hk")
    item = create_item(user: recipient, title: "Desk Lamp")

    expected_message = "#{actor.display_name} completed the transaction for Desk Lamp."

    expect {
      Notification.create!(
        recipient:,
        actor:,
        notifiable: item,
        action: "offer_completed"
      )
    }.to have_broadcasted_to("notifications_user_#{recipient.id}").with(
      hash_including(
        action: "offer_completed",
        actor_name: actor.display_name,
        item_name: "Desk Lamp",
        offer_price_hkd: nil,
        message: expected_message,
        count: 1
      )
    )
  end
end
