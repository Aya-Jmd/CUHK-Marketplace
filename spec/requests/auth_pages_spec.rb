require "rails_helper"
require "cgi"

RSpec.describe "Authentication pages", type: :request do
  it "renders sign-in without the shared header or footer" do
    get new_user_session_path

    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect(document.at_css(".site-header")).not_to be_present
    expect(document.at_css(".site-footer")).not_to be_present
    expect(document.at_css(".auth-shell__background")).to be_present
    expect(response.body).to include("Sign in")
  end

  it "renders sign-up without the shared header or footer" do
    get new_user_registration_path

    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect(document.at_css(".site-header")).not_to be_present
    expect(document.at_css(".site-footer")).not_to be_present
    expect(document.css(".auth-shell__item").size).to be >= 4
    expect(response.body).to include("Create your account")
  end

  it "persists the default campus location during sign up" do
    college = create_college(name: "Shaw")

    expect do
      post user_registration_path, params: {
        user: {
          email: "signup_location_user@cuhk.edu.hk",
          password: "password123",
          password_confirmation: "password123",
          college_id: college.id,
          default_location: "shaw",
          latitude: 22.4179,
          longitude: 114.2065
        }
      }
    end.to change(User, :count).by(1)

    user = User.find_by!(email: "signup_location_user@cuhk.edu.hk")

    expect(user.default_location).to eq("shaw")
    expect(user.latitude).to eq(22.4179)
    expect(user.longitude).to eq(114.2065)
  end

  it "falls back to the college default campus location during sign up when none is chosen" do
    college = create_college(name: "Shaw College")

    expect do
      post user_registration_path, params: {
        user: {
          email: "signup_college_default_user@cuhk.edu.hk",
          password: "password123",
          password_confirmation: "password123",
          college_id: college.id,
          default_location: "",
          latitude: "",
          longitude: ""
        }
      }
    end.to change(User, :count).by(1)

    user = User.find_by!(email: "signup_college_default_user@cuhk.edu.hk")

    expect(user.default_location).to eq("shaw")
    expect(user.latitude).to eq(22.4179)
    expect(user.longitude).to eq(114.2065)
  end

  it "does not allow users to change college through account settings" do
    old_college = create_college(name: "Old College")
    new_college = create_college(name: "New College")
    user = create_user(email: "account_settings_user@cuhk.edu.hk", college: old_college, password: "password123")

    sign_in user
    put user_registration_path, params: {
      user: {
        email: user.email,
        college_id: new_college.id,
        current_password: "password123"
      }
    }

    expect(response).to redirect_to(root_path)
    expect(user.reload.college_id).to eq(old_college.id)
  end
end
