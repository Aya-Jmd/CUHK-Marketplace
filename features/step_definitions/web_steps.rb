# features/step_definitions/web_steps.rb

When('I visit the login page') do
  visit new_user_session_path
end

When('I go to the {string} page') do |page_name|
  case page_name
  when "New Item" then visit new_item_path
  else visit root_path
  end
end

When('I am on the marketplace page') do
  visit root_path
end

When('I fill in {string} with {string}') do |field, value|
  fill_in field, with: value
end

When('I fill in the search bar with {string}') do |query|
  fill_in 'Search', with: query # Adjust 'Search' to match your actual input name/id
end

When('I search for {string}') do |query|
  fill_in 'Search', with: query
  click_button 'Search'
end

When('I click {string}') do |button|
  click_on button
end

When('I click on the seller name {string}') do |seller_name|
  click_link seller_name
end

When('I check {string}') do |checkbox|
  check checkbox
end

When('I leave {string} unchecked') do |checkbox|
  uncheck checkbox
end

Then('I should see {string}') do |content|
  expect(page).to have_content(content)
end

Then('I should see {string} in the results') do |content|
  expect(page).to have_content(content)
end

Then('I should not see {string}') do |content|
  expect(page).not_to have_content(content)
end

Then('the {string} field should be empty') do |field|
  expect(page).to have_field(field, with: '')
end

Then('the {string} field should be pre-filled with {string}') do |field, value|
  expect(page).to have_field(field, with: value)
end

Then('I should see a success message') do
  expect(page).to have_css('.notice') # Adjust class based on your flash messages
end

When('I visit the sign up page') do
  visit new_user_registration_path # This is the standard Devise signup route
end

When('I select {string} from {string}') do |option, dropdown|
  select option, from: dropdown
end

Then('I should see a confirmation that my account was created') do
  # This matches the standard Devise success flash message
  expect(page).to have_content('Welcome! You have signed up successfully') 
end