class Admin::ItemReportsController < Admin::BaseController
  before_action :set_item_report
  before_action :ensure_pending_report!, only: [ :ignore, :delete_item ]
  before_action :authorize_report_resolution!

  def ignore
    @item_report.resolve!(resolver: current_user, resolution: :ignored)
    redirect_back fallback_location: notifications_path, notice: "Report ignored."
  end

  def delete_item
    pending_reports = @item_report.item.item_reports.pending.to_a

    ItemReport.transaction do
      @item_report.item.update!(status: "removed")
      pending_reports.each do |report|
        report.resolve!(resolver: current_user, resolution: :item_deleted)
      end
    end

    redirect_back fallback_location: notifications_path, notice: "Item removed from the marketplace."
  end

  private

  def set_item_report
    @item_report = ItemReport.find(params[:id])
  end

  def ensure_pending_report!
    return if @item_report.pending?

    redirect_back fallback_location: notifications_path, alert: "This report has already been resolved."
  end

  def authorize_report_resolution!
    return if current_user.admin?
    return if current_user.college_admin? && current_user.college_id == @item_report.item.college_id

    redirect_back fallback_location: notifications_path, alert: "You are not allowed to resolve this report."
  end
end
