require "test_helper"
require "securerandom"

class CurrencyDisplayTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    suffix = SecureRandom.hex(4)
    @college = College.create!(name: "Engineering", listing_expiry_days: 30)
    @user = User.create!(
      email: "currency-display-#{suffix}@example.com",
      password: "password123",
      password_confirmation: "password123",
      college: @college
    )
    @category = Category.create!(name: "Books #{suffix}")
    @other_category = Category.create!(name: "Clothing #{suffix}")

    Currency.find_or_create_by!(code: "HKD") do |currency|
      currency.name = "HK Dollar"
      currency.symbol = "HK$"
      currency.rate_from_hkd = 1.0
    end
    Currency.find_or_create_by!(code: "USD") do |currency|
      currency.name = "US Dollar"
      currency.symbol = "US$"
      currency.rate_from_hkd = 0.127
    end

    Item.create!(
      title: "Cheap book",
      description: "Low price",
      price: 100,
      user: @user,
      college: @college,
      category: @category
    )
    Item.create!(
      title: "Expensive book",
      description: "High price",
      price: 250,
      user: @user,
      college: @college,
      category: @category
    )
    Item.create!(
      title: "Winter jacket",
      description: "Outerwear",
      price: 80,
      user: @user,
      college: @college,
      category: @other_category
    )

    sign_in @user
    patch currency_url, params: { currency: "USD" }
  end

  test "items index filters using the active currency and renders the selected currency formatter" do
    get items_url, params: { price_currency: "USD", min_price: 13, max_price: 20 }

    assert_response :success
    assert_includes response.body, 'const currencyCode = "USD";'
    assert_not_includes response.body, "&quot;USD&quot;"
    assert_includes response.body, "Cheap book"
    assert_not_includes response.body, "Expensive book"
  end

  test "analytics dashboard serializes chart labels and values in the active currency" do
    get category_prices_dashboard_url, params: {
      category_ids: [@category.id, @other_category.id],
      chart_mode: "exact",
      start_date: Date.current - 1.day,
      end_date: Date.current + 1.day
    }

    assert_response :success
    assert_includes response.body, '"currency_code":"USD"'
    assert_includes response.body, '"initial_mode":"exact"'
    assert_includes response.body, "\"name\":\"#{@category.name}\""
    assert_includes response.body, "\"name\":\"#{@other_category.name}\""
    assert_not_includes response.body, "&quot;USD&quot;"
    assert_includes response.body, 'value="exact"'
    assert_includes response.body, 'text: "Price (" + data.currency_code + ")"'
    assert_includes response.body, "12.7"
    assert_includes response.body, "10.16"
    assert_includes response.body, "31.75"
  end
end
