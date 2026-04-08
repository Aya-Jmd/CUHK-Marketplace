module ItemsHelper
def market_card_price(item)
  return "" if item.price.blank?

  display_price(item.price)
end

  def market_card_meta(item)
    [
      item.category&.name || "Uncategorized",
      item.college&.name || "CUHK",
      "#{time_ago_in_words(item.created_at)} ago"
    ].join(" | ")
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
