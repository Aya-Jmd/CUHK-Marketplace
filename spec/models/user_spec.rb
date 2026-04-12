require "rails_helper"

RSpec.describe User, type: :model do
  it "requires a college for students but not for admins" do
    student = User.new(
      email: "student_without_college@cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      role: :student
    )
    admin = User.new(
      email: "admin_without_college@cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )

    expect(student).not_to be_valid
    expect(student.errors[:college]).to include("can't be blank")
    expect(admin).to be_valid
  end

  it "tracks the ban lifecycle and authentication state" do
    moderator = create_user(email: "user_spec_moderator@cuhk.edu.hk", role: :admin)
    user = create_user(email: "user_spec_ban_target@cuhk.edu.hk")

    expect(user).to be_active_for_authentication

    user.ban!(actor: moderator)

    expect(user.reload).to be_banned
    expect(user.banned_by).to eq(moderator)
    expect(user).not_to be_active_for_authentication
    expect(user.inactive_message).to eq(:locked)

    user.unban!

    expect(user.reload).not_to be_banned
    expect(user.banned_by).to be_nil
    expect(user).to be_active_for_authentication
  end

  it "formats display and location helpers" do
    user = create_user(email: "display_name_user@cuhk.edu.hk")

    expect(user.display_name).to eq("display_name_user")
    expect(user.has_location?).to be(false)
    expect(user.location_display_name).to eq("Location not set")
    expect(user.location_coordinates).to be_nil

    user.update!(default_location: "new_asia", latitude: 22.4188, longitude: 114.2078)

    expect(user.has_location?).to be(true)
    expect(user.location_display_name).to eq("New Asia")
    expect(user.location_coordinates).to eq({ lat: 22.4188, lng: 114.2078 })
  end

  it "sets a saved campus location when the key is known" do
    user = create_user(email: "user_spec_location_success@cuhk.edu.hk")

    expect(user.set_location("library")).to be(true)
    expect(user.reload.default_location).to eq("library")
    expect(user.latitude).to eq(22.4180)
    expect(user.longitude).to eq(114.2068)
  end

  it "ignores unknown campus location keys" do
    user = create_user(email: "user_spec_location_unknown@cuhk.edu.hk")

    expect(user.set_location("unknown_place")).to be_nil
    expect(user.reload.default_location).to be_nil
    expect(user.latitude).to be_nil
    expect(user.longitude).to be_nil
  end
end
