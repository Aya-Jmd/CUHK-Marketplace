module ItemsHelper
  def favorited_item?(item)
    return false unless user_signed_in?

    ids = @favorited_item_ids
    return current_user.favorites.exists?(item_id: item.id) if ids.nil?

    ids.include?(item.id)
  end

  def favorite_button_dom_id(item, context = "market_card")
    dom_id(item, :"favorite_button_#{normalized_favorite_context(context)}")
  end

  def normalized_favorite_context(context)
    context.to_s.presence || "market_card"
  end

  def market_card_price(item)
    return "" if item.price.blank?

    display_price(item.price)
  end

  def market_card_age(item)
    seconds = Time.current - item.created_at

    case seconds
    when 0...60
      "Now"
    when 60...3600
      minutes = (seconds / 60).floor
      "#{minutes} #{'minute'.pluralize(minutes)} ago"
    when 3600...86_400
      hours = (seconds / 3600).floor
      "#{hours} #{'hour'.pluralize(hours)} ago"
    when 86_400...604_800
      days = (seconds / 86_400).floor
      "#{days} #{'day'.pluralize(days)} ago"
    when 604_800...2_592_000
      weeks = (seconds / 604_800).floor
      "#{weeks} #{'week'.pluralize(weeks)} ago"
    when 2_592_000...31_536_000
      months = (seconds / 2_592_000).floor
      "#{months} #{'month'.pluralize(months)} ago"
    else
      years = (seconds / 31_536_000).floor
      "#{years} #{'year'.pluralize(years)} ago"
    end
  end

  def market_card_meta(item)
    [
      item.category&.name || "Uncategorized",
      item.college&.name || "CUHK",
      "#{time_ago_in_words(item.created_at)} ago"
    ].join(" | ")
  end

  def item_placeholder_initials(item)
    initials = item.title.to_s.scan(/\b[[:alnum:]]/).join.upcase.first(2)
    initials.presence || "CU"
  end

  private

  def market_card_currency_prefix
    case current_currency_code
    when "USD" then "US$"
    when "EUR" then "EUR "
    else "HK$"
    end
  end
end
