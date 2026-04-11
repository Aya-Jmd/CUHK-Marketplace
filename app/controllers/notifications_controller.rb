class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @selected_category = normalized_notification_category
    @show_unread_only = show_unread_only?

    base_scope = current_user.notifications
    filtered_base_scope = @show_unread_only ? base_scope.unread : base_scope

    @category_counts = notification_category_counts(filtered_base_scope)
    @has_unread_notifications = apply_notification_category(base_scope.unread, @selected_category).exists?
    @notifications =
      apply_notification_category(
        filtered_base_scope.includes(:actor, :notifiable),
        @selected_category
      ).order(created_at: :desc)
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.update(read_at: Time.current) if notification.read_at.nil?

    redirect_to safe_notification_redirect_path
  end


  def mark_all_as_read
    apply_notification_category(current_user.notifications.unread, normalized_notification_category)
      .update_all(read_at: Time.current)

    redirect_to notifications_path(notification_filter_params(
      category: normalized_notification_category,
      show_unread_only: show_unread_only?
    ))
  end

  private

  def apply_notification_category(scope, category)
    case category
    when "offers"
      scope.where("action LIKE ?", "offer_%")
    when "all_reports"
      scope.where("action LIKE ?", "item_report_%")
    when "pending_reports"
      scope
        .where("action LIKE ?", "item_report_%")
        .where(notifiable_type: "ItemReport", notifiable_id: ItemReport.pending.select(:id))
    else
      scope
    end
  end

  def normalized_notification_category
    allowed_categories = %w[all offers]
    allowed_categories += %w[all_reports pending_reports] if report_categories_available?

    requested_category = params[:category].to_s
    allowed_categories.include?(requested_category) ? requested_category : "all"
  end

  def show_unread_only?
    params[:show_unread] != "0"
  end

  def report_categories_available?
    current_user.admin? || current_user.college_admin?
  end

  def notification_category_counts(scope)
    counts = {
      "all" => scope.count,
      "offers" => scope.where("action LIKE ?", "offer_%").count
    }

    if report_categories_available?
      report_scope = scope.where("action LIKE ?", "item_report_%")
      counts["all_reports"] = report_scope.count
      counts["pending_reports"] = report_scope.where(notifiable_type: "ItemReport", notifiable_id: ItemReport.pending.select(:id)).count
    end

    counts
  end

  def notification_filter_params(category:, show_unread_only:)
    {
      category: category,
      show_unread: show_unread_only ? "1" : "0"
    }
  end

  def safe_notification_redirect_path
    redirect_path = params[:redirect_to].to_s
    return redirect_path if redirect_path.start_with?("/") && !redirect_path.start_with?("//")

    dashboard_path
  end
end
