class Admin::UsersController < Admin::BaseController
  before_action :set_user
  before_action :authorize_user_management!
  before_action :prevent_self_moderation!, only: [ :ban, :unban ]

  def ban
    if @user.banned?
      redirect_to admin_root_path, alert: "#{@user.email} is already banned."
      return
    end

    @user.ban!(actor: current_user)
    redirect_to admin_root_path, notice: "#{@user.email} was banned."
  end

  def unban
    unless @user.banned?
      redirect_to admin_root_path, alert: "#{@user.email} is not banned."
      return
    end

    @user.unban!
    redirect_to admin_root_path, notice: "#{@user.email} was unbanned."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user_management!
    return if current_user.admin?
    return if current_user.college_admin? && @user.student? && @user.college_id == current_user.college_id

    redirect_to admin_root_path, alert: "You are not allowed to manage that user."
  end

  def prevent_self_moderation!
    return unless @user == current_user

    redirect_to admin_root_path, alert: "You cannot ban or unban your own account."
  end
end
