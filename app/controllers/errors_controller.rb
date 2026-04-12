class ErrorsController < ApplicationController
  skip_before_action :reject_banned_user!
  skip_before_action :force_admin_setup_completion!

  def not_found
    render_not_found("The page you were looking for does not exist or may have been moved.")
  end
end
