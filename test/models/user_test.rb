require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "admin can exist without a college" do
    user = User.new(
      email: "admin-no-college@example.com",
      password: "Admin12345",
      password_confirmation: "Admin12345",
      role: :admin,
      college: nil
    )

    assert user.valid?
  end

  test "student still requires a college" do
    user = User.new(
      email: "student-no-college@example.com",
      password: "Student12345",
      password_confirmation: "Student12345",
      role: :student,
      college: nil
    )

    assert_not user.valid?
    assert_includes user.errors[:college], "can't be blank"
  end
end
