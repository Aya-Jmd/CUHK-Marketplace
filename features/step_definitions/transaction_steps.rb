# features/step_definitions/transaction_steps.rb

Given('I am logged in as the seller {string}') do |email|
  # Create the user in the test database
  @seller = User.create!(email: email, password: 'password', password_confirmation: 'password')

  # Tell Capybara (the fake browser) to log in
  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: 'password'
  click_button 'Log in'
end

Given('I have an item {string} with an {string} offer of HK${int}') do |title, status, price|
  @buyer = User.create!(email: 'buyer@cuhk.edu.hk', password: 'password', password_confirmation: 'password')
  @item = Item.create!(title: title, price: price, user: @seller, status: 'pending_dropoff')
  @offer = Offer.create!(item: @item, buyer: @buyer, seller: @seller, price: price, status: status)
end

Given('the agreed meetup PIN is {string}') do |pin|
  # Bypass the before_create callback to force the specific PIN for the test
  @offer.update_column(:meetup_code, pin)
end

When('I am on my dashboard') do
  # Visit the seller's profile/dashboard page
  visit user_path(@seller)
end

When('I fill in the {string} field with {string}') do |field, value|
  # PRO TIP: Because we used Stimulus to make the beautiful 4-box PIN input,
  # the actual form field is hidden. Capybara needs `visible: false` to type into it!
  find("input[name='#{field}']", visible: false).set(value)
end

When('I press {string}') do |button|
  click_button button
end

Then('I should see a success notice {string}') do |message|
  expect(page).to have_content(message)
end

Then('I should see an error alert {string}') do |message|
  expect(page).to have_content(message)
end

Then('the item {string} should no longer be in the active listings') do |title|
  # Check the database to ensure the state machine worked
  @item.reload
  expect(@item.status).to eq('sold')
end
