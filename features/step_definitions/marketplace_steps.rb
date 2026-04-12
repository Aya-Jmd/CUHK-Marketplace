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

Given("an admin user {string} exists with role {string} in college {string} and setup {string}") do |email, role, college_name, setup|
  college = College.find_by!(name: college_name)
  user = User.find_or_initialize_by(email:)
  user.password = "password"
  user.password_confirmation = "password"
  user.college = college
  user.role = role
  user.setup_completed = (setup == "true")
  user.save!
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
  click_button "Sign in"
end

When("I visit the homepage") do
  visit root_path
end

When("I visit the admin dashboard") do
  visit admin_root_path
end

When("I visit search page with query {string}") do |query|
  visit search_path(q: query)
end

When("I open item {string}") do |title|
  @opened_item = Item.find_by!(title:)
  visit item_path(@opened_item)
end

When("I submit offer price {string}") do |amount|
  item = @opened_item || Item.order(:created_at).last
  page.driver.submit :post, item_offers_path(item), { offer: { price: amount }, offer_currency: "HKD" }
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

When("I invite admin user {string} with role {string} and college {string}") do |email, role, college_name|
  college = College.find_by!(name: college_name)
  role_label = role == "college_admin" ? "College Admin" : "Super Admin"
  fill_in "Email address", with: email
  select role_label, from: "Admin scope"
  select college.name, from: "Assign to college"
  click_button "Generate Credentials"
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

Then("I should be on the admin setup page") do
  expect(page).to have_current_path(edit_admin_setup_path)
end

Then("invited user {string} should exist with role {string}") do |email, role|
  invited = User.find_by(email:)
  expect(invited).to be_present
  expect(invited.role).to eq(role)
end

Then("conversation should not exist for item {string} between {string} and {string}") do |item_title, buyer_email, seller_email|
  item = Item.find_by!(title: item_title)
  buyer = User.find_by!(email: buyer_email)
  seller = User.find_by!(email: seller_email)
  expect(Conversation.where(item:, buyer:, seller:)).to be_empty
end

Given("{string} favorited item {string}") do |user_email, item_title|
  user = User.find_by!(email: user_email)
  item = Item.find_by!(title: item_title)
  Favorite.find_or_create_by!(user:, item:)
end

Given("item {string} has status {string}") do |item_title, status|
  Item.find_by!(title: item_title).update!(status:)
end

When("I favorite item {string}") do |item_title|
  item = Item.find_by!(title: item_title)
  page.driver.submit :post, item_favorite_path(item), {}
end

When("I visit my dashboard") do
  visit dashboard_path
end

When("I ban user {string}") do |email|
  user = User.find_by!(email:)
  page.driver.submit :patch, ban_admin_user_path(user), {}
end

Then("my dashboard favorites should include {string}") do |title|
  expect(page).to have_content(title)
end

Then("my dashboard favorites should not include {string}") do |title|
  expect(page).not_to have_content(title)
end

Then("user {string} should be banned") do |email|
  expect(User.find_by!(email: email)).to be_banned
end

Then("user {string} should not be banned") do |email|
  expect(User.find_by!(email: email)).not_to be_banned
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should not see {string}") do |text|
  expect(page).not_to have_content(text)
end
