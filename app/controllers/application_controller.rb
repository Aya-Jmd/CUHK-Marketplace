class ApplicationController < ActionController::Base
  # redirecting unsigned-in users to sign in page (except for devise's controlers)
  before_action :authenticate_user!, unless: :devise_controller? # Devise's controllers are accessible without authentication
  before_action :reject_banned_user!, unless: :devise_controller?
  helper_method :current_currency_code, :current_currency, :selected_marketplace_college

  rescue_from ActiveRecord::RecordNotFound, with: :rsrc_not_found


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
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :college_id ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :college_id ])
  end
  # Devise looks for this method to know where to send a user after login
  def after_sign_in_path_for(resource)
    # Check if the user logging in is an admin (or college_admin)
    if resource.admin? || resource.college_admin?

      # If they are an admin, check our setup flag
      if resource.setup_completed?
        root_path       # Setup is done, go to home page
      else
        edit_admin_setup_path
      end

    else
      # If they are just a regular student, do the normal Devise behavior (go to homepage)
      super
    end
  end
  # --- DEVISE CONFIGURATION END ---

  private

  def rsrc_not_found(exception)
    case controller_name
    when "users"
        @error_msg = "The requested user does not exist."
    when "items"
        @error_msg = "The requested item does not exist."
    else
        @error_msg  = "The requested data does not exist."
    end
      render "errors/not_found"
    end

  def reject_banned_user!
    return unless current_user&.banned?

    sign_out current_user
    redirect_to new_user_session_path, alert: "Your account has been banned."
  end

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

  def normalized_marketplace_scope(raw_scope)
    raw_scope.to_s == "college" ? "college" : "all"
  end

  def marketplace_listing_relation
    relation = Item.available.includes(:college, :category)
    return relation unless current_user

    relation.where.not(user_id: current_user.id)
  end


  # add this private method
  def selected_marketplace_college
    return unless current_user&.admin?
    return if params[:college_scope_id].blank?

    @selected_marketplace_college ||= College.find_by(id: params[:college_scope_id])
  end


  def apply_marketplace_scope(scope, relation)
    if current_user&.admin?
      return relation.where(college_id: selected_marketplace_college.id) if selected_marketplace_college.present?
      return relation
    end

    if normalized_marketplace_scope(scope) == "college"
      return relation.none unless current_user&.college_id.present?
      return relation.where(college_id: current_user.college_id)
    end

    return relation.where(is_global: true) unless current_user&.college_id.present?

    relation.where("items.is_global = :global OR items.college_id = :college_id",
      global: true,
      college_id: current_user.college_id)
  end


end
