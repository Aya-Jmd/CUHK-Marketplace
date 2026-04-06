class Currency < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, :symbol, :rate_from_hkd, presence: true

  # base is HKD
  BASE_CODE = "HKD"

  def self.base
    find_by!(code: BASE_CODE)
  end

  def self.for(code)
    find_by(code: code) || base
  end

  # amount is in HKD
  def self.convert_from_hkd(amount_hkd, to_code)
    to_currency = Currency.for(to_code)
    return amount_hkd if to_currency.code == BASE_CODE # no unecessary conversion
    amount_hkd * to_currency.rate_from_hkd
  end

    # amount is in other currency (eg : user puts offer while viewing in other currency)
    def self.convert_to_hkd(amount, from_code)
        currency = Currency.for(from_code)
        return amount if currency.code == BASE_CODE
        amount / currency.rate_from_hkd
    end
end
