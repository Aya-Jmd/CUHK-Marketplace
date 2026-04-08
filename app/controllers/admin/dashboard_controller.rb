# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < Admin::BaseController
  def index
    if current_user.admin?
      @total_users = User.count
      @total_items = Item.available.count
      @colleges = College.all
      # Super Admin sees everyone, ordered by most recent
      @users = User.includes(:college).order(created_at: :desc)
    elsif current_user.college_admin?
      @total_users = User.where(college_id: current_user.college_id).count
      @total_items = Item.available.where(college_id: current_user.college_id).count

      # College Admin only sees people in their college
      @users = User.where(college_id: current_user.college_id).order(created_at: :desc)
    end

    @new_admin = User.new
  end

  def invite
    role_to_invite = params[:user][:role]

    # Security: Prevent College Admins from creating Super Admins
    if current_user.college_admin? && role_to_invite == "admin"
      redirect_to admin_root_path, alert: "Unauthorized: You can only invite other College Admins."
      return
    end

    # Auto-assign the college if the inviter is a college_admin
    assigned_college_id = current_user.college_admin? ? current_user.college_id : params[:user][:college_id]

    # Generate a secure 8-character temporary password
    temporary_password = SecureRandom.hex(4)

    @new_admin = User.new(
        email: params[:user][:email],
        role: params[:user][:role], # Ensure this matches 'college_admin' exactly
        college_id: assigned_college_id,
        password: temporary_password,
        password_confirmation: temporary_password,
        setup_completed: false # Explicitly force false
      )

    if @new_admin.save
      # In production, you would send an email here using ActionMailer.
      # For now, we will print the temporary password on the screen so you can test it.
      redirect_to admin_root_path, notice: "Invitation sent! The temporary password for #{@new_admin.email} is: #{temporary_password}"
    else
      redirect_to admin_root_path, alert: "Error sending invite: #{@new_admin.errors.full_messages.join(', ')}"
    end
  end
end
