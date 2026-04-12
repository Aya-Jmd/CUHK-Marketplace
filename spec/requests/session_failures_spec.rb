require "rails_helper"

RSpec.describe "Session failures", type: :request do
  it "shows a banned message when a banned user tries to sign in" do
    moderator = create_user(email: "session_moderator@cuhk.edu.hk", role: :admin)
    user = create_user(email: "session_banned@cuhk.edu.hk", password: "password123")
    user.ban!(actor: moderator)

    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your account is banned.")
  end

  it "shows a wrong password message for existing users" do
    user = create_user(email: "session_wrong_password@cuhk.edu.hk", password: "password123")

    post user_session_path, params: { user: { email: user.email, password: "incorrect-password" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Wrong password")
  end

  it "shows the default invalid message for unknown users" do
    post user_session_path, params: { user: { email: "missing_user@cuhk.edu.hk", password: "password123" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(I18n.t("devise.failure.invalid", authentication_keys: "email"))
  end

  it "redirects incomplete admins to secure their account after sign in" do
    admin = create_user(email: "session_incomplete_admin@cuhk.edu.hk", role: :college_admin, password: "password123")
    admin.update!(setup_completed: false)

    post user_session_path, params: { user: { email: admin.email, password: "password123" } }

    expect(response).to redirect_to(edit_admin_setup_path)
  end
end
