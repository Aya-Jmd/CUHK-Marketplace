require "rails_helper"

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
end
