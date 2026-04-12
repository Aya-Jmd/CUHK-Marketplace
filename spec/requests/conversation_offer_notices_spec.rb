require "rails_helper"

RSpec.describe "Conversation offer notices", type: :request do
  it "creates a conversation and notice when a buyer makes a first offer" do
    seller = create_user(email: "notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Desk")

    sign_in buyer
    post item_offers_path(item), params: { offer: { price: 130 }, offer_currency: "HKD" }

    conversation = Conversation.find_by!(item:, buyer:, seller:)
    last_message = conversation.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_created")
    expect(last_message.offer_notice_amount_hkd).to eq(BigDecimal("130"))

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{buyer.display_name}")
    expect(response.body).to include("made a")
    expect(response.body).to include("HK$130.00")
    expect(response.body).to include("offer.")
  end

  it "renders a cancellation notice in the conversation thread" do
    seller = create_user(email: "cancel_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "cancel_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Shelf")
    conversation = Conversation.create!(item:, buyer:, seller:)
    offer = Offer.create!(item:, buyer:, seller:, price: 220, status: "accepted")

    sign_in seller
    patch cancel_offer_path(offer)

    last_message = conversation.reload.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_cancelled")

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{seller.display_name}")
    expect(response.body).to include("cancelled the transaction.")
    expect(response.body).not_to include("The item may be available again.")
  end

  it "renders an accepted-offer notice in the conversation thread" do
    seller = create_user(email: "accept_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "accept_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Camera")
    conversation = Conversation.create!(item:, buyer:, seller:)
    offer = Offer.create!(item:, buyer:, seller:, price: 260, status: "pending")

    sign_in seller
    patch accept_offer_path(offer)

    last_message = conversation.reload.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_accepted")

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{seller.display_name}")
    expect(response.body).to include("accepted the offer for this item.")
  end

  it "renders a withdrawn-offer notice in the conversation thread" do
    seller = create_user(email: "withdraw_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "withdraw_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Speaker")
    conversation = Conversation.create!(item:, buyer:, seller:)
    offer = Offer.create!(item:, buyer:, seller:, price: 180, status: "pending")

    sign_in buyer
    delete offer_path(offer)

    last_message = conversation.reload.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_withdrawn")

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{buyer.display_name}")
    expect(response.body).to include("cancelled the offer.")
  end

  it "renders a declined-offer notice in the conversation thread" do
    seller = create_user(email: "declined_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "declined_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Headphones")
    conversation = Conversation.create!(item:, buyer:, seller:)
    offer = Offer.create!(item:, buyer:, seller:, price: 190, status: "pending")

    sign_in seller
    patch decline_offer_path(offer)

    last_message = conversation.reload.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_declined")

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("#{seller.display_name}")
    expect(response.body).to include("declined the offer.")
  end

  it "renders the completed transaction notice in the conversation thread" do
    seller = create_user(email: "complete_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "complete_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Monitor")
    conversation = Conversation.create!(item:, buyer:, seller:)
    offer = Offer.create!(item:, buyer:, seller:, price: 310, status: "accepted")
    offer.update_column(:meetup_code, "1234")

    sign_in seller
    patch complete_offer_path(offer), params: { meetup_code: "1234" }

    last_message = conversation.reload.messages.order(:created_at).last

    expect(last_message.marketplace_notice_type).to eq("offer_completed")

    get conversations_path(conversation_id: conversation.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("The transaction has been completed, this item is sold.")
  end

  it "shows the item page as a fresh offer after the seller declines" do
    seller = create_user(email: "decline_notice_seller@cuhk.edu.hk")
    buyer = create_user(email: "decline_notice_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Notice Pen")
    offer = Offer.create!(item:, buyer:, seller:, price: 210, status: "pending")

    sign_in seller
    patch decline_offer_path(offer)

    sign_out seller
    sign_in buyer
    get item_path(item)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Make an offer")
    expect(response.body).to include("Make offer")
    expect(response.body).not_to include("Update your offer")
    expect(response.body).not_to include("value=\"210.0\"")
  end
end
