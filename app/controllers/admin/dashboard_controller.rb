class Admin::DashboardController < Admin::BaseController
  def index
    if current_user.admin?
      @total_users = User.count
      @total_items = Item.available.count
      @colleges = College.all
      @report_scope = ItemReport.includes(:item)
      @users = User.includes(:college).order(created_at: :desc)
    elsif current_user.college_admin?
      @total_users = User.where(college_id: current_user.college_id).count
      @total_items = Item.available.where(college_id: current_user.college_id).count
      @report_scope = ItemReport.joins(:item).where(items: { college_id: current_user.college_id })

      @users = User.where(college_id: current_user.college_id).order(created_at: :desc)
    end

    @total_reports = @report_scope.count
    @pending_reports = @report_scope.pending.count
    @new_admin = User.new
  end

  def invite
    role_to_invite = params[:user][:role]

    if current_user.college_admin? && role_to_invite == "admin"
      redirect_to admin_root_path, alert: "Unauthorized: You can only invite other College Admins."
      return
    end

    assigned_college_id = current_user.college_admin? ? current_user.college_id : params[:user][:college_id]

    temporary_password = SecureRandom.hex(4)

    @new_admin = User.new(
      email: params[:user][:email],
      role: params[:user][:role],
      college_id: assigned_college_id,
      password: temporary_password,
      password_confirmation: temporary_password,
      setup_completed: false
    )

    if @new_admin.save
      # Surface the temporary password in development-style flows until mail delivery is wired in.
      redirect_to admin_root_path, notice: "Invitation sent! The temporary password for #{@new_admin.email} is: #{temporary_password}"
    else
      redirect_to admin_root_path, alert: "Error sending invite: #{@new_admin.errors.full_messages.join(', ')}"
    end
  end
end
