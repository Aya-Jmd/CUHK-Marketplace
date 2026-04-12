require "rails_helper"

RSpec.describe "Admin and Setup Flows", type: :request do
  it "blocks non-admin users from admin dashboard" do
    user = create_user(email: "student_admin_block@cuhk.edu.hk")
    sign_in user

    get admin_root_path

    expect(response).to redirect_to(root_path)
  end

  it "forces admin setup before admin dashboard access" do
    admin = create_user(email: "college_admin_setup@cuhk.edu.hk", role: :college_admin)
    admin.update!(setup_completed: false)
    sign_in admin

    get admin_root_path

    expect(response).to redirect_to(edit_admin_setup_path)
  end

  it "forces incomplete admins back to setup even on non-admin pages" do
    admin = create_user(email: "incomplete_admin_root@cuhk.edu.hk", role: :college_admin)
    admin.update!(setup_completed: false)
    sign_in admin

    get root_path

    expect(response).to redirect_to(edit_admin_setup_path)
  end

  it "completes admin setup and marks account secured" do
    admin = create_user(email: "setup_patch@cuhk.edu.hk", role: :college_admin)
    admin.update!(setup_completed: false)
    sign_in admin

    patch admin_setup_path, params: { user: { password: "password123", password_confirmation: "password123" } }

    expect(response).to redirect_to(admin_root_path)
    expect(admin.reload.setup_completed).to be(true)
  end

  it "prevents college admin from inviting super admins" do
    college_admin = create_user(email: "college_admin_inviter@cuhk.edu.hk", role: :college_admin)
    college_admin.update!(setup_completed: true)
    sign_in college_admin

    post admin_invite_path, params: { user: { email: "x@cuhk.edu.hk", role: "admin" } }

    expect(response).to redirect_to(admin_root_path)
    expect(User.find_by(email: "x@cuhk.edu.hk")).to be_nil
  end

  it "allows super admin to invite a college admin" do
    target_college = create_college(name: "S.H. Ho")
    super_admin = create_user(email: "super_admin_inviter@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)
    sign_in super_admin

    post admin_invite_path, params: {
      user: {
        email: "new_college_admin@cuhk.edu.hk",
        role: "college_admin",
        college_id: target_college.id
      }
    }

    invited = User.find_by(email: "new_college_admin@cuhk.edu.hk")
    expect(response).to redirect_to(admin_root_path)
    expect(invited).to be_present
    expect(invited.role).to eq("college_admin")
    expect(invited.college_id).to eq(target_college.id)
    expect(invited.setup_completed).to be(false)
  end

  it "renders admin setup without the shared header or footer and shows the auth scene" do
    admin = create_user(email: "setup_page_visual@cuhk.edu.hk", role: :college_admin)
    admin.update!(setup_completed: false)
    sign_in admin

    get edit_admin_setup_path

    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect(document.at_css(".site-header")).not_to be_present
    expect(document.at_css(".site-footer")).not_to be_present
    expect(document.at_css(".auth-shell__background")).to be_present
    expect(response.body).to include("responsibilities")
  end
end
