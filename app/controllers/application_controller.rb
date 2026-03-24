class ApplicationController < ActionController::Base
  # redirecting unsigned-in users to sign in page (except for devise's controlers)
  before_action :authenticate_user!, unless: :devise_controller? # Devise's controllers are accessible without authentication
  
  helper_method :current_currency_code, :current_currency
  
  
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

  private

  def current_currency_code
    session[:currency_code] || Currency::BASE_CODE
  end

  def current_currency
    @current_currency ||= Currency.for(current_currency_code)
  end

  def convert_price_from_hkd(amount_hkd)
    return if amount_hkd.nil?

    Currency.convert_from_hkd(amount_hkd.to_d, current_currency_code)
  end

  def convert_price_to_hkd(amount)
    return if amount.nil?

    Currency.convert_to_hkd(amount.to_d, current_currency_code)
  end
end
