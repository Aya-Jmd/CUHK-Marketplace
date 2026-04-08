require "database_cleaner/active_record"

DatabaseCleaner.strategy = :transaction

Before do
  DatabaseCleaner.start
  Currency.find_or_create_by!(code: "HKD") do |currency|
    currency.name = "Hong Kong Dollar"
    currency.symbol = "HK$"
    currency.rate_from_hkd = 1
  end

  Currency.find_or_create_by!(code: "USD") do |currency|
    currency.name = "US Dollar"
    currency.symbol = "$"
    currency.rate_from_hkd = 0.128
  end

  Currency.find_or_create_by!(code: "EUR") do |currency|
    currency.name = "Euro"
    currency.symbol = "EUR"
    currency.rate_from_hkd = 0.118
  end
end

After do
  DatabaseCleaner.clean
end
