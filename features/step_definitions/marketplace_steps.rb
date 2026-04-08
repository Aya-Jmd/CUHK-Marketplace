Given("a college named {string}") do |name|
  College.find_or_create_by!(name:)
end

Given("a user exists with email {string} in college {string}") do |email, college_name|
  college = College.find_by!(name: college_name)
  User.find_or_create_by!(email:) do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.college = college
  end
end

Given("category {string} exists") do |name|
  Category.find_or_create_by!(name:)
end

Given("{string} listed {string} as local") do |seller_email, title|
  seller = User.find_by!(email: seller_email)
  Item.create!(title:, price: 100, user: seller, college: seller.college, is_global: false, status: "available")
end

Given("{string} listed {string} as global") do |seller_email, title|
  seller = User.find_by!(email: seller_email)
  Item.create!(title:, price: 100, user: seller, college: seller.college, is_global: true, status: "available")
end

Given("{string} listed {string} in category {string}") do |seller_email, title, category_name|
  seller = User.find_by!(email: seller_email)
  category = Category.find_by!(name: category_name)
  Item.create!(title:, price: 100, user: seller, college: seller.college, is_global: true, status: "available", category:)
end

Given("offer exists on {string} from {string} with status {string} and code {string}") do |item_title, buyer_email, status, code|
  item = Item.find_by!(title: item_title)
  buyer = User.find_by!(email: buyer_email)
  @offer = Offer.create!(item:, buyer:, seller: item.user, price: 120, status:)
  @offer.update_column(:meetup_code, code)
end

Given("an offer exists on {string} from {string}") do |item_title, buyer_email|
  item = Item.find_by!(title: item_title)
  buyer = User.find_by!(email: buyer_email)
  Offer.create!(item:, buyer:, seller: item.user, price: 120, status: "pending")
end

Given("I am logged in as {string}") do |email|
  visit new_user_session_path
  fill_in "Email", with: email
  fill_in "Password", with: "password"
  click_button "Log in"
end

When("I visit the homepage") do
  visit root_path
end

When("I visit search page with query {string}") do |query|
  visit search_path(q: query)
end

When("I open item {string}") do |title|
  item = Item.find_by!(title:)
  visit item_path(item)
end

When("I submit offer price {string}") do |amount|
  fill_in "offer_price", with: amount
  click_button "Send Offer"
end

When("I send initial chat message {string}") do |message|
  fill_in "message[content]", with: message
  click_button "Send message"
end

When("I complete that offer using code {string}") do |code|
  page.driver.submit :patch, complete_offer_path(@offer), { meetup_code: code }
end

When("I mark all my notifications as read") do
  page.driver.submit :patch, mark_all_as_read_notifications_path, {}
end

Then("the latest offer for {string} should belong to {string}") do |item_title, buyer_email|
  item = Item.find_by!(title: item_title)
  expect(item.offers.order(:created_at).last.buyer.email).to eq(buyer_email)
end

Then("the latest offer status should be {string}") do |status|
  expect(Offer.order(:created_at).last.status).to eq(status)
end

Then("that offer should have status {string}") do |status|
  expect(@offer.reload.status).to eq(status)
end

Then("item {string} should have status {string}") do |title, status|
  expect(Item.find_by!(title:).status).to eq(status)
end

Then("conversation for item {string} should include message {string}") do |title, message|
  item = Item.find_by!(title:)
  conversation = Conversation.find_by!(item:)
  expect(conversation.messages.pluck(:content)).to include(message)
end

Then("I should have no unread notifications") do
  user = User.find_by!(email: "seller@cuhk.edu.hk")
  expect(user.notifications.unread.count).to eq(0)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end
