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
end
