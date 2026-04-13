require "rails_helper"

RSpec.describe User, type: :model do
  it "requires a college for students but not for admins" do
    student = User.new(
      email: "student_without_college@cuhk.edu.hk",
      pseudo: "student",
      password: "password123",
      password_confirmation: "password123",
      role: :student
    )
    admin = User.new(
      email: "admin_without_college@cuhk.edu.hk",
      pseudo: "admin",
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
    user = create_user(email: "display_user@cuhk.edu.hk")

    expect(user.display_name).to eq("display_user")
    expect(user.has_location?).to be(false)
    expect(user.location_display_name).to eq("Location not set")
    expect(user.location_coordinates).to be_nil

    user.update!(default_location: "new_asia", latitude: 22.4188, longitude: 114.2078)

    expect(user.has_location?).to be(true)
    expect(user.location_display_name).to eq("New Asia")
    expect(user.location_coordinates).to eq({ lat: 22.4188, lng: 114.2078 })
  end

  it "rejects pseudos longer than fifteen characters" do
    user = build_user_with_pseudo("this_display_name_is_too_long")

    expect(user).not_to be_valid
    expect(user.errors[:pseudo]).to include("is too long (maximum is 15 characters)")
  end

  it "rejects inappropriate pseudos" do
    user = build_user_with_pseudo("fuck")

    expect(user).not_to be_valid
    expect(user.errors[:pseudo]).to include(User::INAPPROPRIATE_PSEUDO_MESSAGE)
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

  it "encrypts admin invite pins and clears them once setup is complete" do
    inviter = create_user(email: "user_spec_inviter@cuhk.edu.hk", role: :admin)
    invitee = User.new(
      email: "user_spec_invitee@cuhk.edu.hk",
      pseudo: "invitee",
      password: "ABCDEFGH",
      password_confirmation: "ABCDEFGH",
      role: :college_admin,
      college: create_college(name: "Invite Pin College"),
      setup_completed: false,
      invited_by: inviter
    )

    invitee.store_admin_invite_pin("ABCD2345")
    invitee.save!

    expect(invitee.reload.invite_pin_ciphertext).not_to eq("ABCD2345")
    expect(invitee.reveal_admin_invite_pin).to eq("ABCD2345")

    invitee.update!(setup_completed: true)

    expect(invitee.reload.invite_pin_ciphertext).to be_nil
  end

  def build_user_with_pseudo(pseudo)
    User.new(
      email: "pseudo_test_user@cuhk.edu.hk",
      pseudo: pseudo,
      password: "password123",
      password_confirmation: "password123",
      role: :student,
      college: create_college(name: "Pseudo College")
    )
  end
end
