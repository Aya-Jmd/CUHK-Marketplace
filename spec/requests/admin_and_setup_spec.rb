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

  it "shows system-wide users to a super admin" do
    college_a = create_college(name: "Super Admin A")
    college_b = create_college(name: "Super Admin B")
    super_admin = create_user(email: "dashboard_super_admin@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)
    visible_user = create_user(email: "visible_user@cuhk.edu.hk", college: college_a)
    other_user = create_user(email: "other_visible_user@cuhk.edu.hk", college: college_b)
    create_item(user: visible_user, title: "Visible Listing", college: college_a)
    create_item(user: other_user, title: "Other Visible Listing", college: college_b)

    sign_in super_admin
    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("All colleges are shown here.")
    expect(response.body).to include(visible_user.email)
    expect(response.body).to include(other_user.email)
    expect(response.body).to include("Assign to college")
  end

  it "scopes the dashboard to the college admin's college" do
    home_college = create_college(name: "Home College")
    outside_college = create_college(name: "Outside College")
    college_admin = create_user(email: "scoped_college_admin@cuhk.edu.hk", college: home_college, role: :college_admin)
    college_admin.update!(setup_completed: true)
    same_college_user = create_user(email: "same_college_user@cuhk.edu.hk", college: home_college)
    other_college_user = create_user(email: "other_college_user@cuhk.edu.hk", college: outside_college)
    create_item(user: same_college_user, title: "Scoped Listing", college: home_college)
    create_item(user: other_college_user, title: "Outside Listing", college: outside_college)

    sign_in college_admin
    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Only users from your college are shown here.")
    expect(response.body).to include(same_college_user.email)
    expect(response.body).not_to include(other_college_user.email)
    expect(response.body).not_to include("Assign to college")
  end

  it "forces invited college admins into the inviter's college scope" do
    inviter_college = create_college(name: "Inviter College")
    other_college = create_college(name: "Other Invite College")
    college_admin = create_user(email: "scoped_inviter@cuhk.edu.hk", college: inviter_college, role: :college_admin)
    college_admin.update!(setup_completed: true)

    sign_in college_admin
    post admin_invite_path, params: {
      user: {
        email: "forced_scope_admin@cuhk.edu.hk",
        role: "college_admin",
        college_id: other_college.id
      }
    }

    invited = User.find_by(email: "forced_scope_admin@cuhk.edu.hk")

    expect(response).to redirect_to(admin_root_path)
    expect(invited).to be_present
    expect(invited.college_id).to eq(inviter_college.id)
  end

  it "shows a validation error when an invite cannot be created" do
    super_admin = create_user(email: "invalid_invite_admin@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    post admin_invite_path, params: { user: { email: "", role: "college_admin", college_id: create_college(name: "Invite Validation").id } }
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Error sending invite")
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
