class ApplicationController < ActionController::Base
  before_action :reject_banned_user!, unless: :devise_controller?
  before_action :force_admin_setup_completion!, unless: :devise_controller?
  helper_method :current_currency_code, :current_currency, :selected_marketplace_college, :hide_global_chrome?, :immersive_flash_page?

  rescue_from ActiveRecord::RecordNotFound, with: :rsrc_not_found

  # The UI depends on modern browser features used by Rails 8 and the map/chat flows.
  allow_browser versions: :modern

  # Bust stale HTML when the import map changes.
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    sign_up_keys = [ :college_id, :default_location, :latitude, :longitude ]
    account_update_keys = [ :default_location, :latitude, :longitude ]

    devise_parameter_sanitizer.permit(:sign_up, keys: sign_up_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: account_update_keys)
  end

  def after_sign_in_path_for(resource)
    if resource.admin? || resource.college_admin?
      if resource.setup_completed?
        root_path
      else
        edit_admin_setup_path
      end
    else
      super
    end
  end

  private

  def rsrc_not_found(exception)
    case controller_name
    when "users"
        error_msg = "The requested user does not exist."
    when "items"
        error_msg = "The requested item does not exist."
    else
        error_msg  = "The requested data does not exist."
    end

    render_not_found(error_msg)
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

  def preload_favorited_item_ids(items)
    return @favorited_item_ids = [] unless user_signed_in?

    item_ids = Array(items).flatten.compact.map { |item| item.respond_to?(:id) ? item.id : item }.uniq
    return @favorited_item_ids = [] if item_ids.empty?

    @favorited_item_ids = current_user.favorites.where(item_id: item_ids).pluck(:item_id)
  end

  def hide_global_chrome?
    devise_controller? || controller_path == "admin/setups"
  end

  def immersive_flash_page?
    hide_global_chrome?
  end

  def force_admin_setup_completion!
    return unless current_user&.persisted?
    return unless current_user.admin? || current_user.college_admin?
    return if current_user.setup_completed?
    return if controller_path == "admin/setups"

    redirect_to edit_admin_setup_path, alert: "You must secure your account before continuing."
  end

  def render_not_found(message)
    @error_msg = message

    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found, formats: :html }
      format.any { head :not_found }
    end
  end
end
