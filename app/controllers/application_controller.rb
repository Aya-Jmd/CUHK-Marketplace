class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # --- DEVISE CONFIGURATION START ---
  # Tells Devise to run this extra method before checking security
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Adds college_id to the allowed list for signing up and updating accounts
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:college_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:college_id])
  end
  # --- DEVISE CONFIGURATION END ---
end