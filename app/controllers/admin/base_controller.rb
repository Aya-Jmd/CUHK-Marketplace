class Admin::BaseController < ApplicationController
  before_action :authenticate_user! # Assumes you use Devise
  before_action :ensure_admin!
  before_action :ensure_setup_completed!

  private

  def ensure_admin!
    unless current_user.admin? || current_user.college_admin?
      redirect_to root_path, alert: "Unauthorized access."
    end
  end

  def ensure_setup_completed!
    if !current_user.setup_completed? && controller_name != "setups"
      redirect_to edit_admin_setup_path, alert: "You must secure your account before continuing."
    end
  end
end
