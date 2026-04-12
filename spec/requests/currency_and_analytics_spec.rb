require "rails_helper"

RSpec.describe "Currency and Analytics", type: :request do
  it "updates selected currency for guests" do
    patch currency_path, params: { currency: "USD" }

    expect(response).to redirect_to(root_path)
    expect(session[:currency_code]).to eq("USD")
  end

  it "updates selected currency when code is valid" do
    user = create_user(email: "currency_valid@cuhk.edu.hk")
    sign_in user

    patch currency_path, params: { currency: "USD" }

    expect(response).to redirect_to(root_path)
    expect(session[:currency_code]).to eq("USD")
  end

  it "falls back to HKD for unknown currency code" do
    user = create_user(email: "currency_invalid@cuhk.edu.hk")
    sign_in user

    patch currency_path, params: { currency: "ZZZ" }

    expect(response).to redirect_to(root_path)
    expect(session[:currency_code]).to eq("HKD")
  end

  it "renders analytics dashboard for signed-in users" do
    user = create_user(email: "analytics_user@cuhk.edu.hk")
    category = Category.create!(name: "Stationery")
    create_item(user:, title: "Pen Set", category:, price: 35, is_global: true)
    sign_in user

    get analytics_path, params: { category_ids: [ category.id ], chart_mode: "averages" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Price Analytics")
  end

  it "renders analytics with no category selected by default" do
    user = create_user(email: "analytics_empty_state@cuhk.edu.hk")
    Category.create!(name: "Books")
    Category.create!(name: "Electronics")
    sign_in user

    get analytics_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No selected category. Select one, or multiple, to plot data.")
    expect(response.body).to include('"categories":[]')
    expect(response.body).not_to include('checked="checked"')
  end
end
