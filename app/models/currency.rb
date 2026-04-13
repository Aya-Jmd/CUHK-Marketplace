class Currency < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, :symbol, :rate_from_hkd, presence: true

  BASE_CODE = "HKD"

  def self.base
    find_by!(code: BASE_CODE)
  end

  def self.for(code)
    find_by(code: code) || base
  end

  def self.convert_from_hkd(amount_hkd, to_code)
    to_currency = Currency.for(to_code)
    return amount_hkd.round(2) if to_currency.code == BASE_CODE

    (amount_hkd * to_currency.rate_from_hkd).round(2)
  end

  def self.convert_to_hkd(amount, from_code)
    currency = Currency.for(from_code)
    return amount.round(2) if currency.code == BASE_CODE

    (amount / currency.rate_from_hkd).round(2)
  end
end
