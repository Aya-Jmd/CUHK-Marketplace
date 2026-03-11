module ApplicationHelper



    # HELPERS FOR CURRENCY CONVERSION
    def current_currency_code
        session[:currency_code] || Currency::BASE_CODE
    end

    def current_currency
        @current_currency ||= Currency.for(current_currency_code)
    end

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
end

