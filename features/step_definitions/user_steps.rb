# features/step_definitions/user_steps.rb

Given('there is a college named {string}') do |college_name|
  College.find_or_create_by!(name: college_name)
end

Given('there is a user with email {string}, password {string}, and college {string}') do |email, password, college_name|
  college = College.find_by(name: college_name)
  User.create!(email: email, password: password, password_confirmation: password, college: college)
end

Given('there is a seller with email {string} from {string}') do |email, college_name|
  college = College.find_or_create_by!(name: college_name)
  User.create!(email: email, password: 'password', password_confirmation: 'password', college: college)
end

Given('there is a buyer with email {string} from {string}') do |email, college_name|
  college = College.find_or_create_by!(name: college_name)
  User.create!(email: email, password: 'password', password_confirmation: 'password', college: college)
end

Given('I am logged in as {string}') do |email|
  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: 'password' # Assuming standard test password
  click_button 'Log in'
end

Given('I am logged in as a {string} college student') do |college_name|
  college = College.find_or_create_by!(name: college_name)
  user = User.create!(email: "student@#{college_name.downcase}.cuhk.edu.hk", password: 'password', college: college)

  visit new_user_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: 'password'
  click_button 'Log in'
end

Given('I am logged in as a user from {string}') do |college_name|
  step "I am logged in as a \"#{college_name}\" college student"
end

Then('I should be signed in') do
  expect(page).to have_content('Sign out') # Or whatever your logged-in indicator is
end

When('I sign out') do
  click_on 'Sign out'
end

Then('I should be signed out') do
  expect(page).to have_content('Log in')
end

Then('I should be redirected to the login page') do
  expect(current_path).to eq(new_user_session_path)
end

Then('I should be on the profile page of {string}') do |email|
  user = User.find_by(email: email)
  expect(current_path).to eq(user_path(user))
end

Then('I should be on my profile page') do
  expect(current_path).to eq(user_path(User.last)) # Adjust based on current_user
end

Then('I should see the seller email {string}') do |email|
  expect(page).to have_content(email)
end

Then('I should see the seller college {string}') do |college|
  expect(page).to have_content(college)
end

Then('I should see my displayed name') do
  expect(page).to have_css('.profile-name') # Adjust CSS selector based on your UI
end

Then('I should see my email {string}') do |email|
  expect(page).to have_content(email)
end
