# features/step_definitions/item_steps.rb

Given('there is an item {string}') do |title|
  user = User.first || User.create!(email: "default@test.com", password: "password")
  Item.create!(title: title, price: 100, user: user, status: "available")
end

Given('there is an item {string} priced {string} in category {string}') do |title, price, category_name|
  user = User.first || User.create!(email: "default@test.com", password: "password")
  category = Category.find_or_create_by!(name: category_name)
  Item.create!(title: title, price: price.to_f, user: user, category: category, status: "available")
end

Given('there is an item {string} listed under {string} that is not global') do |title, college_name|
  college = College.find_by(name: college_name)
  user = User.create!(email: "seller_#{title.delete(' ')}@test.com", password: 'password', college: college)
  Item.create!(title: title, price: 100, user: user, is_global: false, status: "available")
end

Given('there is an item {string} listed under {string} that is marked as global') do |title, college_name|
  college = College.find_by(name: college_name)
  user = User.create!(email: "seller_#{title.delete(' ')}@test.com", password: 'password', college: college)
  Item.create!(title: title, price: 100, user: user, is_global: true, status: "available")
end

Given('there is an item {string} listed by {string}') do |title, email|
  user = User.find_by(email: email)
  Item.create!(title: title, price: 100, user: user, status: "available")
end

When('I visit the {string} marketplace page') do |type|
  if type == "Local College"
    visit items_path(scope: 'local') # Adjust route params based on your app
  elsif type == "Global"
    visit items_path(scope: 'global')
  end
end

When('I open the item page for {string}') do |title|
  click_link title
end

When('I choose category {string}') do |category|
  select category, from: 'Category' # Assumes a dropdown menu
end

When('I set the minimum price to {string}') do |price|
  fill_in 'Min Price', with: price
end

When('I set the maximum price to {string}') do |price|
  fill_in 'Max Price', with: price
end

When('I click {string} to apply filters') do |button|
  click_button button
end

Then('the item should appear on the marketplace') do
  visit root_path
  expect(page).to have_content(Item.last.title)
end

# --- CHAT & ANALYTICS STUBS ---
# Note: These might require specific UI selectors depending on how you built them

Then('a live chat with {string} should start') do |email|
  expect(page).to have_css('#chat-window') # Adjust to your chat container ID
end

Then('the chat should be linked to the item {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should see {string} in the chat header') do |email|
  within('#chat-header') do
    expect(page).to have_content(email)
  end
end

Given('there are historical prices for category {string}') do |category|
  # Stub for your analytics database setup
end

When('I visit the price analytics dashboard') do
  visit analytics_path
end

When('I select category {string}') do |category|
  select category, from: 'Category'
end

When('I choose item {string}') do |item_title|
  select item_title, from: 'Item'
end

Then('I should see a historical price trend chart for {string}') do |category|
  expect(page).to have_css('canvas') # Assuming Chart.js renders a canvas
end

Then('I should see summary metrics for {string}') do |category|
  expect(page).to have_content("Average Price")
end

Then('I should see the item\'s price compared with historical category prices') do
  expect(page).to have_content("Comparison")
end

Then('I should see a fairness indicator for the item\'s price') do
  expect(page).to have_css('.fairness-badge') # Adjust CSS to your actual indicator
end

Given('there is an item {string} listed by {string} at map location {string}') do |title, email, location|
  user = User.find_by(email: email)
  # NOTE: Change 'location_name' to whatever column you actually use for locations in your DB!
  Item.create!(title: title, price: 100, user: user, status: "available", location_name: location)
end

Then('I should see a campus map') do
  # Assumes your Leaflet map container has an ID or Class of 'map'
  expect(page).to have_css('#map', visible: :all)
end

Then('I should see a marker for {string}') do |title|
  # Leaflet uses this specific CSS class for its map pins
  expect(page).to have_css('.leaflet-marker-icon')
end

Then('I should see the location label {string}') do |label|
  expect(page).to have_content(label)
end

When('I enable my location') do
  # HACK: Headless browsers don't have real GPS. We have to inject JavaScript
  # to mock the HTML5 Geolocation API and pretend the test runner is standing in CUHK!
  page.execute_script("
    navigator.geolocation.getCurrentPosition = function(success) {
      success({coords: {latitude: 22.4195, longitude: 114.2067}});
    };
  ")

  # Trigger whatever button on your UI asks for the user's location
  # NOTE: Change "Find My Location" to match your actual button text
  click_button 'Find My Location'
end

Then('I should see my current location on the map') do
  # Assuming you give your user location marker a specific class in your Leaflet JS
  expect(page).to have_css('.user-location-marker')
end

Then('I should see the distance from me to {string}') do |title|
  # Checks if the UI renders the distance calculation text
  expect(page).to have_content('km away')
end
