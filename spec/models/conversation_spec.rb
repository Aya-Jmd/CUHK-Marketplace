require "rails_helper"

RSpec.describe Conversation, type: :model do
  it "enforces uniqueness per buyer seller item triple" do
    seller = create_user(email: "conv_seller@cuhk.edu.hk")
    buyer = create_user(email: "conv_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Printer")

    Conversation.create!(buyer:, seller:, item:)
    duplicate = Conversation.new(buyer:, seller:, item:)

    expect(duplicate).not_to be_valid
  end

  it "returns correct participant checks and other user" do
    seller = create_user(email: "conv_seller_2@cuhk.edu.hk")
    buyer = create_user(email: "conv_buyer_2@cuhk.edu.hk")
    outsider = create_user(email: "conv_outsider@cuhk.edu.hk")
    item = create_item(user: seller, title: "Monitor")
    conversation = Conversation.create!(buyer:, seller:, item:)

    expect(conversation.participant?(buyer)).to be(true)
    expect(conversation.participant?(outsider)).to be(false)
    expect(conversation.other_user_for(buyer)).to eq(seller)
  end
end
