require "rails_helper"

RSpec.describe "Admin user moderation", type: :request do
  it "allows a college admin to ban a student from the same college" do
    college = create_college(name: "Shaw")
    college_admin = create_user(email: "moderator_same_college@cuhk.edu.hk", college:, role: :college_admin)
    college_admin.update!(setup_completed: true)
    student = create_user(email: "student_same_college@cuhk.edu.hk", college:)

    sign_in college_admin
    patch ban_admin_user_path(student)

    expect(response).to redirect_to(admin_root_path)
    expect(student.reload).to be_banned
    expect(student.banned_by).to eq(college_admin)
  end

  it "prevents a college admin from banning a student from another college" do
    shaw = create_college(name: "Shaw")
    new_asia = create_college(name: "New Asia")
    college_admin = create_user(email: "moderator_other_college@cuhk.edu.hk", college: shaw, role: :college_admin)
    college_admin.update!(setup_completed: true)
    outsider = create_user(email: "outside_scope_student@cuhk.edu.hk", college: new_asia)

    sign_in college_admin
    patch ban_admin_user_path(outsider)

    expect(response).to redirect_to(admin_root_path)
    expect(outsider.reload).not_to be_banned
  end

  it "prevents admins from banning their own account" do
    admin = create_user(email: "self_moderation_admin@cuhk.edu.hk", role: :admin)
    admin.update!(setup_completed: true)

    sign_in admin
    patch ban_admin_user_path(admin)

    expect(response).to redirect_to(admin_root_path)
    expect(admin.reload).not_to be_banned
  end

  it "allows a super admin to unban a previously banned student" do
    admin = create_user(email: "unban_admin@cuhk.edu.hk", role: :admin)
    admin.update!(setup_completed: true)
    actor = create_user(email: "prior_ban_actor@cuhk.edu.hk", role: :admin)
    actor.update!(setup_completed: true)
    student = create_user(email: "banned_student@cuhk.edu.hk")
    student.ban!(actor:)

    sign_in admin
    patch unban_admin_user_path(student)

    expect(response).to redirect_to(admin_root_path)
    expect(student.reload).not_to be_banned
    expect(student.banned_by).to be_nil
  end
end
