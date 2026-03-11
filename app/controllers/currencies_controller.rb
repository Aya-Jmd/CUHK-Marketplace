class CurrenciesController < ApplicationController
  before_action :authenticate_user!

  def update
    code = params[:currency]&.upcase

    if Currency.exists?(code: code)
      session[:currency_code] = code
    else
      session[:currency_code] = Currency::BASE_CODE
    end

    redirect_back fallback_location: root_path
  end
end
