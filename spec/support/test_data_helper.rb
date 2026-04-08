module TestDataHelper
  def ensure_currencies!
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

  def create_college(name: "Shaw")
    College.find_or_create_by!(name:)
  end

  def create_user(email:, college: nil, role: :student, password: "password")
    User.create!(
      email:,
      password:,
      password_confirmation: password,
      college: college || create_college,
      role:
    )
  end

  def create_item(user:, title: "Item", price: 100, status: "available", is_global: true, category: nil, college: nil, latitude: nil, longitude: nil)
    Item.create!(
      user:,
      college: college || user.college,
      category: category,
      title:,
      price:,
      status:,
      is_global:,
      latitude:,
      longitude:
    )
  end
end
