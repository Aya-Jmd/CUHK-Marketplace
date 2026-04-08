require "rails_helper"

RSpec.describe "Item reports", type: :request do
  let!(:college) { College.create!(name: "Shaw College", listing_expiry_days: 30) }
  let!(:category) { Category.create!(name: "Textbook") }
  let!(:seller) do
    User.create!(
      email: "seller@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:reporter) do
    User.create!(
      email: "reporter@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: college
    )
  end
  let!(:admin) do
    User.create!(
      email: "admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin,
      setup_completed: true
    )
  end
  let!(:college_admin) do
    User.create!(
      email: "college-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :college_admin,
      college: college,
      setup_completed: true
    )
  end
  let!(:item) do
    Item.create!(
      title: "Suspicious listing",
      price: 400,
      description: "Needs review",
      status: "available",
      user: seller,
      college: college,
      category: category
    )
  end

  it "creates a report and notifies admins for the item college" do
    sign_in reporter

    expect do
      post item_item_reports_path(item), params: {
        item_report: { message: "This looks fraudulent." }
      }
    end.to change(ItemReport, :count).by(1)

    report = ItemReport.order(:created_at).last

    expect(report.reporter).to eq(reporter)
    expect(Notification.where(action: "item_report_created", notifiable: report).pluck(:recipient_id)).to match_array([admin.id, college_admin.id])
  end

  it "marks report notifications resolved and removes the item when an admin deletes it" do
    report = ItemReport.create!(item: item, reporter: reporter, message: "Please remove this.")

    sign_in admin

    patch delete_item_admin_item_report_path(report)

    expect(response).to redirect_to(notifications_path)
    expect(item.reload.status).to eq("removed")
    expect(report.reload).to be_item_deleted
    expect(Notification.where(action: "item_report_created", notifiable: report).pluck(:read_at)).to all(be_present)
    expect(Notification.where(action: "item_report_resolved", notifiable: report).pluck(:recipient_id)).to match_array([admin.id, college_admin.id])
  end
end
