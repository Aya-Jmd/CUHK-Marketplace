require "rails_helper"

RSpec.describe "Item reports", type: :request do
  let!(:college) do
    College.find_or_create_by!(name: "Shaw College") do |college|
      college.slug = "shaw-college"
      college.listing_expiry_days = 30
    end
  end
  let!(:category) { Category.find_or_create_by!(name: "Textbook") }
  let(:expected_reviewer_ids) { User.admin.or(User.college_admin.where(college_id: college.id)).distinct.pluck(:id) }
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
      email: "item-reports-admin@example.com",
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
    expect(Notification.where(action: "item_report_created", notifiable: report).pluck(:recipient_id)).to match_array(expected_reviewer_ids)
  end

  it "hard deletes the item and its report notifications when an admin deletes it" do
    report = ItemReport.create!(item: item, reporter: reporter, message: "Please remove this.")
    created_notification_ids = Notification.where(action: "item_report_created", notifiable: report).pluck(:id)

    sign_in admin

    patch delete_item_admin_item_report_path(report)

    expect(response).to redirect_to(notifications_path)
    expect(Item.exists?(item.id)).to be(false)
    expect(ItemReport.exists?(report.id)).to be(false)
    expect(Notification.where(id: created_notification_ids)).to be_empty

    get item_path(item.id)

    expect(response).to have_http_status(:not_found)
  end
end
