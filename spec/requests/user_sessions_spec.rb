require "rails_helper"

RSpec.describe "User sessions", type: :request do
  let!(:college) { College.create!(name: "Shaw", listing_expiry_days: 30) }
  let!(:user) do
    User.create!(
      email: "user@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end

  it "shows an inline wrong password message when authentication fails for an existing user" do
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "wrong-password"
      }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Wrong password")
    expect(response.body).to include("Log in")
  end

  it "shows a banned message when a banned user tries to sign in" do
    user.update!(banned_at: Time.current)

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Your account has been banned.")
  end
end
