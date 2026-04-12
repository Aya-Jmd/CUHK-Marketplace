require "rails_helper"

RSpec.describe "Notifications management", type: :request do
  it "shows only unread offer notifications by default" do
    seller = create_user(email: "notif_filter_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_filter_buyer@cuhk.edu.hk")
    visible_item = create_item(user: seller, title: "Unread Offer Item")
    hidden_item = create_item(user: seller, title: "Read Offer Item")

    Notification.create!(recipient: seller, actor: buyer, notifiable: visible_item, action: "offer_created", amount_hkd: 100)
    Notification.create!(recipient: seller, actor: buyer, notifiable: hidden_item, action: "offer_created", amount_hkd: 120, read_at: Time.current)

    sign_in seller
    get notifications_path, params: { category: "offers" }

    document = Nokogiri::HTML.parse(response.body)
    notification_cards = document.css(".notification-card")

    expect(response).to have_http_status(:ok)
    expect(notification_cards.size).to eq(1)
    expect(notification_cards.first.text).to include("Unread Offer Item")
    expect(notification_cards.first.text).not_to include("Read Offer Item")
  end

  it "includes read notifications when unread-only is disabled" do
    seller = create_user(email: "notif_all_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_all_buyer@cuhk.edu.hk")
    unread_item = create_item(user: seller, title: "Unread Desk")
    read_item = create_item(user: seller, title: "Read Desk")

    Notification.create!(recipient: seller, actor: buyer, notifiable: unread_item, action: "offer_created", amount_hkd: 90)
    Notification.create!(recipient: seller, actor: buyer, notifiable: read_item, action: "offer_created", amount_hkd: 95, read_at: Time.current)

    sign_in seller
    get notifications_path, params: { category: "offers", show_unread: "0" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Unread Desk")
    expect(response.body).to include("Read Desk")
  end

  it "shows only pending reports in the pending reports tab for admins" do
    college = create_college(name: "Notifications College")
    admin = create_user(email: "notif_admin@cuhk.edu.hk", role: :admin)
    admin.update!(setup_completed: true)
    seller = create_user(email: "notif_report_seller@cuhk.edu.hk", college:)
    reporter = create_user(email: "notif_reporter@cuhk.edu.hk", college:)
    pending_item = create_item(user: seller, title: "Pending Report Item", college:)
    resolved_item = create_item(user: seller, title: "Resolved Report Item", college:)

    create_item(user: seller, title: "Neutral Item", college:)
    pending_report = ItemReport.create!(item: pending_item, reporter:, message: "Needs review")
    resolved_report = ItemReport.create!(item: resolved_item, reporter:, message: "Already handled")
    resolved_report.resolve!(resolver: admin, resolution: :ignored)

    sign_in admin
    get notifications_path, params: { category: "pending_reports", show_unread: "0" }

    document = Nokogiri::HTML.parse(response.body)
    notification_cards = document.css(".notification-card")

    expect(response).to have_http_status(:ok)
    expect(notification_cards.size).to eq(1)
    expect(notification_cards.first.text).to include("Pending Report Item")
    expect(notification_cards.first.text).not_to include("Resolved Report Item")
    expect(pending_report).to be_pending
  end

  it "falls back to the all tab when a student requests report-only filters" do
    seller = create_user(email: "notif_student_scope_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_student_scope_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Student Scope Item")
    offer = Offer.create!(item:, buyer:, seller:, price: 80)
    Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")

    sign_in seller
    get notifications_path, params: { category: "pending_reports" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Student Scope Item")
    expect(response.body).not_to include("Pending Reports")
  end

  it "marks a notification as read and follows a safe internal redirect" do
    seller = create_user(email: "notif_mark_read_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_mark_read_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Internal Redirect Item")
    offer = Offer.create!(item:, buyer:, seller:, price: 77)
    notification = Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")

    sign_in seller
    patch mark_as_read_notification_path(notification), params: { redirect_to: item_path(item) }

    expect(response).to redirect_to(item_path(item))
    expect(notification.reload.read_at).to be_present
  end

  it "rejects unsafe external redirects when marking a notification as read" do
    seller = create_user(email: "notif_unsafe_redirect_seller@cuhk.edu.hk")
    buyer = create_user(email: "notif_unsafe_redirect_buyer@cuhk.edu.hk")
    item = create_item(user: seller, title: "Unsafe Redirect Item")
    offer = Offer.create!(item:, buyer:, seller:, price: 66)
    notification = Notification.create!(recipient: seller, actor: buyer, notifiable: offer, action: "offer_created")

    sign_in seller
    patch mark_as_read_notification_path(notification), params: { redirect_to: "//evil.example" }

    expect(response).to redirect_to(dashboard_path)
    expect(notification.reload.read_at).to be_present
  end

  it "marks only the selected notification category as read" do
    admin = create_user(email: "notif_mark_all_admin@cuhk.edu.hk", role: :admin)
    admin.update!(setup_completed: true)
    buyer = create_user(email: "notif_mark_all_buyer@cuhk.edu.hk")
    item = create_item(user: admin, title: "Admin Offer Item", college: create_college(name: "Admin Offers"))
    offer = Offer.create!(item:, buyer:, seller: admin, price: 88)
    offer_notification = Notification.create!(recipient: admin, actor: buyer, notifiable: offer, action: "offer_created")

    reporter = create_user(email: "notif_mark_all_reporter@cuhk.edu.hk", college: item.college)
    report = ItemReport.create!(item:, reporter:, message: "Please review")
    report_notification = admin.notifications.where(notifiable: report, action: "item_report_created").first

    sign_in admin
    patch mark_all_as_read_notifications_path, params: { category: "offers", show_unread: "0" }

    expect(response).to redirect_to(notifications_path(category: "offers", show_unread: "0"))
    expect(offer_notification.reload.read_at).to be_present
    expect(report_notification.reload.read_at).to be_nil
  end
end
