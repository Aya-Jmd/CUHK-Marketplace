module ApplicationHelper
  MARKETPLACE_COLLEGE_SLUGS = %w[
    chung-chi
    new-asia
    united
    shaw
    morningside
    s-h-ho
    c-w-chu
    wu-yee-sun
    lee-woo-sing
  ].freeze

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

  def notification_message(notification)
    offer = notification.notifiable if notification.notifiable.is_a?(Offer)
    item = notification.notifiable if notification.notifiable.is_a?(Item)
    report = notification.notifiable if notification.notifiable.is_a?(ItemReport)
    offer_amount_hkd = notification[:amount_hkd] || offer&.price
    item_name = offer&.item&.title || report&.item&.title || item&.title || "your item"

    case notification.action
    when "offer_created", "made an offer on"
      "#{notification.actor.display_name} has made an offer of #{display_price(offer&.price)} for your item #{item_name}!"
    when "offer_updated"
      "#{notification.actor.display_name} updated their offer to #{display_price(offer&.price)} for your item #{item_name}."
    when "offer_withdrawn"
      "#{notification.actor.display_name} has cancelled their offer of #{display_price(offer_amount_hkd)} for item #{item_name}."
    when "offer_declined", "declined your offer for"
      "#{notification.actor.display_name} declined the offer."
    when "offer_accepted", "accepted your offer for"
      "#{notification.actor.display_name} accepted your offer for the item #{item_name}. See your dashboard for the confirmation pin!"
    when "offer_cancelled", "cancelled the transaction for"
      "#{notification.actor.display_name} cancelled the transaction for the item #{item_name}."
    when "offer_completed", "confirmed the sale of"
      "#{notification.actor.display_name} confirmed the sale of the item #{item_name}."
    when "item_report_created"
      "#{notification.actor.display_name} reported the item #{item_name} for review."
    when "item_report_resolved"
      "#{notification.actor.display_name} resolved the report for #{item_name}."
    else
      "#{notification.actor.display_name} #{notification.action}."
    end
  end

  def marketplace_scope(raw_scope = params[:scope])
    raw_scope.to_s == "college" ? "college" : "all"
  end

  def marketplace_college_label
    name = current_user&.college&.name.to_s.strip
    return "My College" if name.blank?

    name.sub(/\s+College\z/i, "").presence || name
  end

  def marketplace_base_params(scope = params[:scope])
    if current_user&.admin?
      return params[:college_scope_id].present? ? { college_scope_id: params[:college_scope_id] } : {}
    end

    { scope: marketplace_scope(scope) }
  end

  def marketplace_scope_label(scope = params[:scope])
    return selected_marketplace_college&.name || "CUHK Global" if current_user&.admin?

    marketplace_scope(scope) == "college" ? marketplace_college_label : "CUHK"
  end


  def marketplace_scope_switch_path(target_scope)
    preserved_params =
      case [ controller.controller_name, controller.action_name ]
      when [ "search", "index" ]
        params.permit(:q, :category_id, :sort, :price_currency, :min_price, :max_price).to_h.symbolize_keys
      when [ "items", "index" ]
        params.permit(:price_currency, :min_price, :max_price).to_h.symbolize_keys
      else
        {}
      end

    route_params = preserved_params.merge(marketplace_base_params(target_scope))

    if controller.controller_name == "search" && controller.action_name == "index"
      search_path(route_params)
    else
      items_path(route_params)
    end
  end

  def marketplace_theme_name
    if controller.controller_name == "items" && controller.action_name == "show"
      return theme_slug_for_college(@item&.college)
    end

    if current_user&.admin?
      return theme_slug_for_college(selected_marketplace_college) if selected_marketplace_college.present?

      return "global"
    end

    if %w[items search].include?(controller.controller_name) && marketplace_scope != "college"
      return "global"
    end

    theme_slug_for_college(current_user&.college)
  end

  def theme_slug_for_college(college)
    slug = college_slug(college)
    return slug if MARKETPLACE_COLLEGE_SLUGS.include?(slug)

    "global"
  end

  def college_slug(college)
    return if college.blank?

    college.try(:slug).presence || college.name.to_s.parameterize.delete_suffix("-college")
  end

  # Hero title that changes based on selected college
  def marketplace_hero_title
    if current_user&.admin? && params[:college_scope_id].present?
      college = College.find_by(id: params[:college_scope_id])
      return "#{college.name.delete_suffix(" College")} Marketplace" if college.present?
    end

    if current_user && marketplace_scope == "college" && current_user.college.present?
      return "#{current_user.college.name.delete_suffix(" College")} Marketplace"
    end

    "CUHK Marketplace"
  end
end
