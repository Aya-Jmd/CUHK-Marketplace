module ApplicationHelper
  # amount_hkd is a numeric value stored in DB in HKD
  def display_price(amount_hkd)
    return "" if amount_hkd.nil?

    converted = Currency.convert_from_hkd(amount_hkd, current_currency.code)
    number_to_currency(
      converted,
      unit: current_currency.symbol,
      precision: 2
    )
  end

  def marketplace_scope(raw_scope = params[:scope])
    raw_scope.to_s == "college" ? "college" : "all"
  end

  def marketplace_college_label
    name = current_user&.college&.name.to_s.strip
    return "My College" if name.blank?

    name.sub(/\s+College\z/i, "").presence || name
  end

  def marketplace_scope_label(scope = params[:scope])
    marketplace_scope(scope) == "college" ? marketplace_college_label : "CUHK"
  end

  def marketplace_scope_switch_path(target_scope)
    preserved_params =
      case [controller.controller_name, controller.action_name]
      when ["search", "index"]
        params.permit(:q, :category_id, :sort, :price_currency, :min_price, :max_price).to_h.symbolize_keys
      when ["items", "index"]
        params.permit(:price_currency, :min_price, :max_price).to_h.symbolize_keys
      else
        {}
      end

    route_params = preserved_params.merge(scope: marketplace_scope(target_scope))

    if controller.controller_name == "search" && controller.action_name == "index"
      search_path(route_params)
    else
      items_path(route_params)
    end
  end

  def marketplace_theme_name
    return "global" unless controller.action_name == "index" && %w[items search].include?(controller.controller_name)
    return "global" unless marketplace_scope == "college"

    slug = current_user&.college&.name.to_s.parameterize.delete_suffix("-college")
    return slug if %w[wu-yee-sun chung-chi].include?(slug)

    "global" #default value
  end
end

