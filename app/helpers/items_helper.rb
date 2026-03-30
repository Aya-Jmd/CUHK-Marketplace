module ItemsHelper
  def market_card_price(item)
    converted_price = item.price ? Currency.convert_from_hkd(item.price.to_d, current_currency_code) : 0
    "#{market_card_currency_prefix}#{converted_price.to_i}"
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
