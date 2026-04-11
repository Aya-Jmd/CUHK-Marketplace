require "rails_helper"
require "capybara/rspec"

RSpec.describe "Chat and Profiles", type: :request do
  it "creates a conversation with initial message from item page" do
    seller = create_user(email: "chat_seller@cuhk.edu.hk")
    buyer = create_user(email: "chat_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Mini Fridge")

    sign_in buyer
    post conversations_path, params: { item_id: item.id, message: { content: "Is this still available?" } }

    conversation = Conversation.last
    expect(response).to redirect_to(conversations_path(conversation_id: conversation.id))
    expect(conversation.item).to eq(item)
    expect(conversation.messages.last.content).to eq("Is this still available?")
  end

  it "prevents non-participants from posting in conversation" do
    seller = create_user(email: "chat_seller_guard@cuhk.edu.hk")
    buyer = create_user(email: "chat_buyer_guard@cuhk.edu.hk")
    outsider = create_user(email: "chat_outsider@cuhk.edu.hk")
    item = create_item(user: seller, title: "Router")
    conversation = Conversation.create!(item:, buyer:, seller:)

    sign_in outsider
    post conversation_messages_path(conversation), params: { message: { content: "intrude" } }

    expect(response).to redirect_to(root_path)
    expect(conversation.messages).to be_empty
  end

  it "renders the custom chat scrollbar shell for the selected conversation" do
    seller = create_user(email: "chat_shell_seller@cuhk.edu.hk")
    buyer = create_user(email: "chat_shell_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Smartcase")
    conversation = Conversation.create!(item:, buyer:, seller:)
    conversation.messages.create!(user: seller, content: "pls")
    conversation.messages.create!(user: buyer, content: "ok")

    sign_in buyer
    get conversations_path(conversation_id: conversation.id)

    document = Capybara.string(response.body)

    expect(response).to have_http_status(:ok)
    expect(document).to have_css(".chat-page__messages-shell[data-controller='chat-scroll']")
    expect(document).to have_css("#messages.chat-page__messages[data-chat-scroll-target='viewport']")
    expect(document).to have_css(".chat-page__custom-scrollbar[data-chat-scroll-target='track']", visible: false)
    expect(document).to have_css(".chat-page__custom-scrollbar-thumb[data-chat-scroll-target='thumb']")
  end

  it "updates current user profile location" do
    college_a = create_college(name: "Shaw")
    college_b = create_college(name: "Morningside")
    user = create_user(email: "profile_user@cuhk.edu.hk", college: college_a)

    sign_in user
    patch profile_path, params: { user: { college_id: college_b.id, default_location: "new_asia", latitude: 22.42, longitude: 114.21 } }

    expect(response).to redirect_to(profile_path)
    expect(user.reload.college_id).to eq(college_b.id)
    expect(user.default_location).to eq("new_asia")
  end
end
