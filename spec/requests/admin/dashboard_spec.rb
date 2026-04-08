require "rails_helper"

RSpec.describe "Admin dashboard", type: :request do
  let!(:admin) do
    User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin,
      setup_completed: true
    )
  end

  it "renders the dashboard for a signed-in admin" do
    sign_in admin

    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("User Management")
  end
end
