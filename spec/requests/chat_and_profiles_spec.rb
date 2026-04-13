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

    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect(document.at_css(".chat-page__messages-shell[data-controller='chat-scroll']")).to be_present
    expect(document.at_css("#messages.chat-page__messages[data-chat-scroll-target='viewport']")).to be_present
    expect(document.at_css(".chat-page__custom-scrollbar[data-chat-scroll-target='track']")).to be_present
    expect(document.at_css(".chat-page__custom-scrollbar-thumb[data-chat-scroll-target='thumb']")).to be_present
  end

  it "renders the username and full item title separately in the conversation thread heading" do
    seller = create_user(email: "chat_layout_seller@cuhk.edu.hk", pseudo: "sellername")
    buyer = create_user(email: "chat_layout_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "A very long listing title that should truncate in the UI")
    conversation = Conversation.create!(item:, buyer:, seller:)
    conversation.messages.create!(user: seller, content: "Still available")

    sign_in buyer
    get conversations_path(conversation_id: conversation.id)

    document = Nokogiri::HTML.parse(response.body)
    thread = document.at_css("##{ActionView::RecordIdentifier.dom_id(conversation, :thread)}")

    expect(response).to have_http_status(:ok)
    expect(thread.at_css(".chat-page__thread-name")&.text).to eq("sellername")
    expect(thread.at_css(".chat-page__thread-item-inline")&.text).to eq(item.title)
    expect(thread.at_css(".chat-page__thread-item-inline")&.[]("title")).to eq(item.title)
  end

  it "updates current user profile location without letting them change college" do
    college_a = create_college(name: "Shaw")
    college_b = create_college(name: "Morningside")
    user = create_user(email: "profile_user@cuhk.edu.hk", college: college_a)

    sign_in user
    patch profile_path, params: { user: { college_id: college_b.id, default_location: "new_asia", latitude: 22.42, longitude: 114.21 } }

    expect(response).to redirect_to(profile_path)
    expect(user.reload.college_id).to eq(college_a.id)
    expect(user.default_location).to eq("new_asia")
  end

  it "updates the current user pseudo from the profile page" do
    user = create_user(email: "profile_rename@cuhk.edu.hk", pseudo: "oldname")

    sign_in user
    patch profile_path, params: { user: { pseudo: "newname" } }

    expect(response).to redirect_to(profile_path)
    expect(user.reload.pseudo).to eq("newname")
  end

  it "renders the username editor in read mode by default with the current pseudo prefilled" do
    user = create_user(email: "profile_inline_form@cuhk.edu.hk", pseudo: "oldname")

    sign_in user
    get profile_path

    document = Nokogiri::HTML.parse(response.body)
    username_editor = document.at_css(".profile-inline-edit")
    read_row = username_editor.at_css(".profile-inline-edit__read-row")
    edit_row = username_editor.at_css(".profile-inline-edit__edit-row")
    pseudo_input = username_editor.at_css("input[name='user[pseudo]']")

    expect(response).to have_http_status(:ok)
    expect(username_editor.css("form.profile-inline-edit__form").size).to eq(1)
    expect(read_row).to be_present
    expect(read_row["hidden"]).to be_nil
    expect(read_row.text).to include("oldname")
    expect(edit_row).to be_present
    expect(edit_row["hidden"]).not_to be_nil
    expect(pseudo_input).to be_present
    expect(pseudo_input["value"]).to eq("oldname")
  end

  it "rejects an inappropriate pseudo from the profile page" do
    user = create_user(email: "profile_bad_name@cuhk.edu.hk", pseudo: "cleanname")

    sign_in user
    patch profile_path, params: { user: { pseudo: "fuck" } }
    document = Nokogiri::HTML.parse(response.body)
    username_editor = document.at_css(".profile-inline-edit")

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.pseudo).to eq("cleanname")
    expect(response.body).to include(User::INAPPROPRIATE_PSEUDO_MESSAGE)
    expect(username_editor.at_css(".profile-inline-edit__read-row")["hidden"]).not_to be_nil
    expect(username_editor.at_css(".profile-inline-edit__edit-row")["hidden"]).to be_nil
  end

  it "renders a seller profile for guests" do
    seller = create_user(email: "public_profile_seller@cuhk.edu.hk")
    create_item(user: seller, title: "Profile Listing")

    get user_path(seller)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(seller.display_name)
    expect(response.body).to include("Browse the items this seller currently has available")
    expect(response.body).to include("Profile Listing")
  end

  it "hides out-of-scope local items from a seller profile" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    seller = create_user(email: "hidden_profile_seller@cuhk.edu.hk", college: new_asia)
    viewer = create_user(email: "hidden_profile_viewer@cuhk.edu.hk", college: shaw)
    create_item(user: seller, title: "Visible Global Listing", college: new_asia, is_global: true)
    create_item(user: seller, title: "Hidden Local Listing", college: new_asia, is_global: false)

    sign_in viewer
    get user_path(seller)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Visible Global Listing")
    expect(response.body).not_to include("Hidden Local Listing")
  end

  it "renders accepted seller and buyer cards with segmented meetup pin UI" do
    owner = create_user(email: "dashboard_owner@cuhk.edu.hk")
    buyer = create_user(email: "dashboard_buyer@cuhk.edu.hk")
    other_seller = create_user(email: "dashboard_other_seller@cuhk.edu.hk")
    selling_item = create_item(user: owner, title: "Shoes")
    buying_item = create_item(user: other_seller, title: "Feather")

    selling_offer = Offer.create!(item: selling_item, buyer:, seller: owner, price: 999, status: "accepted")
    selling_offer.update_column(:meetup_code, "2569")

    buying_offer = Offer.create!(item: buying_item, buyer: owner, seller: other_seller, price: 9, status: "accepted")
    buying_offer.update_column(:meetup_code, "4831")

    sign_in owner
    get dashboard_path

    document = Nokogiri::HTML.parse(response.body)
    seller_card = document.at_css(".profile-item-row--seller-accepted")
    buyer_card = document.at_css(".profile-item-row--buyer-accepted")

    expect(response).to have_http_status(:ok)
    expect(seller_card).to be_present
    expect(seller_card.at_css(".profile-item-row__dashboard-overlay-link")).to be_present
    expect(seller_card.text).to include("Shoes")
    expect(seller_card.text).to include(buyer.display_name)
    expect(seller_card.text).to include("Complete sale")
    expect(seller_card.text).to include("Cancel transaction")
    expect(seller_card.at_css("[data-controller='pin-input']")).to be_present
    expect(seller_card.css(".profile-pin-code__digit--input").size).to eq(4)

    expect(buyer_card).to be_present
    expect(buyer_card.text).to include("Meetup PIN")
    expect(buyer_card.at_css(".profile-item-row__dashboard-overlay-link")).to be_present
    expect(buyer_card.css(".profile-pin-code__digit--filled").map(&:text)).to eq(%w[4 8 3 1])
  end
end
