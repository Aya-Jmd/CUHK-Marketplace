require "rails_helper"

RSpec.describe ItemReport, type: :model do
  it "rejects reports filed by the item owner" do
    owner = create_user(email: "report_owner@cuhk.edu.hk")
    item = create_item(user: owner, title: "Owner Listing")
    report = ItemReport.new(item:, reporter: owner, message: "I should not be able to do this.")

    expect(report).not_to be_valid
    expect(report.errors[:base]).to include("You cannot report your own item.")
  end

  it "marks reviewer notifications read and emits resolved notifications" do
    college = create_college(name: "Shaw")
    seller = create_user(email: "report_seller@cuhk.edu.hk", college:)
    reporter = create_user(email: "reporter_student@cuhk.edu.hk", college:)
    admin = create_user(email: "report_admin@cuhk.edu.hk", role: :admin)
    college_admin = create_user(email: "report_college_admin@cuhk.edu.hk", college:, role: :college_admin)
    item = create_item(user: seller, title: "Reported Listing", college:)
    report = ItemReport.create!(item:, reporter:, message: "This listing breaks the rules.")
    reviewer_ids = User.admin.or(User.college_admin.where(college_id: college.id)).distinct.pluck(:id)

    created_notifications = Notification.where(action: "item_report_created", notifiable: report)

    expect(created_notifications.pluck(:recipient_id)).to match_array(reviewer_ids)

    report.resolve!(resolver: admin, resolution: :ignored)

    resolved_notifications = Notification.where(action: "item_report_resolved", notifiable: report)

    expect(report.reload).to be_ignored
    expect(report.resolved_by).to eq(admin)
    expect(created_notifications.pluck(:read_at)).to all(be_present)
    expect(resolved_notifications.pluck(:recipient_id)).to match_array(reviewer_ids)
  end

  it "rejects pending as a resolution target" do
    seller = create_user(email: "report_pending_seller@cuhk.edu.hk")
    reporter = create_user(email: "report_pending_reporter@cuhk.edu.hk")
    item = create_item(user: seller, title: "Pending Resolution Listing")
    report = ItemReport.create!(item:, reporter:, message: "Needs review.")

    expect do
      report.resolve!(resolver: reporter, resolution: :pending)
    end.to raise_error(ArgumentError, "Pending reports cannot resolve to pending")
  end
end
