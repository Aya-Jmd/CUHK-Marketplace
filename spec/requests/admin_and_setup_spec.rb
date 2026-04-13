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
    expect(invited.invited_by).to eq(super_admin)
    expect(invited.invite_pin_ciphertext).to be_present
    expect(invited.reveal_admin_invite_pin).to match(/\A[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{8}\z/)
    expect(flash[:notice]).to include("Use Manage invite")
    expect(flash[:notice]).not_to include(invited.reveal_admin_invite_pin)
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

  it "shows the manage invite access panel on the admin dashboard" do
    super_admin = create_user(email: "manage_invite_panel@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Manage invite")
    expect(response.body).to include("Enter your password to see invites")
  end

  it "reveals pending invite setup pins for one page load after password confirmation" do
    target_college = create_college(name: "Reveal Invite College")
    super_admin = create_user(email: "reveal_invites_admin@cuhk.edu.hk", role: :admin, password: "password123")
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    post admin_invite_path, params: {
      user: {
        email: "pending_reveal_admin@cuhk.edu.hk",
        role: "college_admin",
        college_id: target_college.id
      }
    }

    invited = User.find_by!(email: "pending_reveal_admin@cuhk.edu.hk")
    setup_pin = invited.reveal_admin_invite_pin

    post admin_reveal_invites_path, params: { invite_access: { password: "password123" } }

    expect(response).to redirect_to(admin_root_path(anchor: "admin-pending-invites"))

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.body).to include("Setup pins")
    expect(response.body).to include(invited.email)
    expect(response.body).to include(setup_pin)

    get admin_root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Setup pins")
    expect(response.body).not_to include(setup_pin)
  end

  it "keeps invite setup pins hidden when the password check fails" do
    target_college = create_college(name: "Hidden Invite College")
    super_admin = create_user(email: "hidden_invites_admin@cuhk.edu.hk", role: :admin, password: "password123")
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    post admin_invite_path, params: {
      user: {
        email: "hidden_pending_admin@cuhk.edu.hk",
        role: "college_admin",
        college_id: target_college.id
      }
    }

    setup_pin = User.find_by!(email: "hidden_pending_admin@cuhk.edu.hk").reveal_admin_invite_pin

    post admin_reveal_invites_path, params: { invite_access: { password: "wrong-password" } }

    expect(response).to redirect_to(admin_root_path(anchor: "admin-invite-access"))

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Incorrect password")
    expect(response.body).not_to include(setup_pin)
  end

  it "only reveals pending setup pins created by the current admin" do
    target_college = create_college(name: "Scoped Reveal College")
    owner_admin = create_user(email: "owner_invites_admin@cuhk.edu.hk", role: :admin, password: "password123")
    owner_admin.update!(setup_completed: true)
    other_admin = create_user(email: "other_invites_admin@cuhk.edu.hk", role: :admin, password: "password123")
    other_admin.update!(setup_completed: true)

    sign_in other_admin
    post admin_invite_path, params: {
      user: {
        email: "other_admin_invite@cuhk.edu.hk",
        role: "college_admin",
        college_id: target_college.id
      }
    }

    hidden_pin = User.find_by!(email: "other_admin_invite@cuhk.edu.hk").reveal_admin_invite_pin

    sign_out other_admin
    sign_in owner_admin
    post admin_reveal_invites_path, params: { invite_access: { password: "password123" } }
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No unfinished invites are assigned to you right now.")
    expect(response.body).not_to include(hidden_pin)
  end

  it "does not show completed invites in the revealed setup pin list" do
    target_college = create_college(name: "Completed Invite College")
    super_admin = create_user(email: "completed_invites_admin@cuhk.edu.hk", role: :admin, password: "password123")
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    post admin_invite_path, params: {
      user: {
        email: "completed_pending_admin@cuhk.edu.hk",
        role: "college_admin",
        college_id: target_college.id
      }
    }

    invited = User.find_by!(email: "completed_pending_admin@cuhk.edu.hk")
    setup_pin = invited.reveal_admin_invite_pin
    invited.update!(setup_completed: true)

    post admin_reveal_invites_path, params: { invite_access: { password: "password123" } }
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No unfinished invites are assigned to you right now.")
    expect(response.body).not_to include(setup_pin)
  end

  it "shows the college rules manager with the first college selected by default for super admins" do
    first_college = create_college(name: "First Rules College")
    second_college = create_college(name: "Second Rules College")
    super_admin = create_user(email: "rules_default_super_admin@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    get admin_root_path

    document = Nokogiri::HTML.parse(response.body)
    selector = document.at_css("select[name='rule_college_id']")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("College Management")
    expect(response.body).to include("College rules")
    expect(selector).to be_present
    expect(selector.at_css("option[selected]")["value"]).to eq(first_college.id.to_s)
    expect(selector.text).to include(second_college.name)
  end

  it "lets a super admin update the rules for the selected college" do
    target_college = create_college(name: "Rules Target College")
    other_college = create_college(name: "Rules Other College")
    super_admin = create_user(email: "rules_super_admin@cuhk.edu.hk", role: :admin)
    super_admin.update!(setup_completed: true)

    sign_in super_admin
    patch admin_college_rules_path, params: {
      college_id: target_college.id,
      college: {
        max_items_per_user: 12,
        max_item_price: 88.5
      }
    }

    expect(response).to redirect_to(admin_root_path(rule_college_id: target_college.id))
    expect(target_college.reload.max_items_per_user).to eq(12)
    expect(target_college.max_item_price).to eq(88.5.to_d)
    expect(other_college.reload.max_items_per_user).to eq(College::DEFAULT_MAX_ITEMS_PER_USER)
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

  it "lets a college admin update only their own college rules" do
    home_college = create_college(name: "Home Rules College")
    other_college = create_college(name: "Other Rules College")
    college_admin = create_user(email: "rules_college_admin@cuhk.edu.hk", college: home_college, role: :college_admin)
    college_admin.update!(setup_completed: true)

    sign_in college_admin
    patch admin_college_rules_path, params: {
      college_id: other_college.id,
      college: {
        max_items_per_user: 7,
        max_item_price: 42
      }
    }

    expect(response).to redirect_to(admin_root_path)
    expect(home_college.reload.max_items_per_user).to eq(7)
    expect(home_college.max_item_price).to eq(42.to_d)
    expect(other_college.reload.max_items_per_user).to eq(College::DEFAULT_MAX_ITEMS_PER_USER)
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
