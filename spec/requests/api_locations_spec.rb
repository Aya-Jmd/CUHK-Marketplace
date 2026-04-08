require "rails_helper"

RSpec.describe "Locations API", type: :request do
  it "returns all campus locations" do
    user = create_user(email: "api_locations_user@cuhk.edu.hk")
    sign_in user

    get "/api/locations/all"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload).to be_an(Array)
    expect(payload.first.keys).to include("key", "name", "lat", "lng")
  end

  it "returns a specific known location by key" do
    user = create_user(email: "api_show_user@cuhk.edu.hk")
    sign_in user

    get "/api/locations/shaw"

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload["name"]).to be_present
    expect(payload["lat"]).to be_present
    expect(payload["lng"]).to be_present
  end

  it "returns 404 for unknown location key" do
    user = create_user(email: "api_missing_user@cuhk.edu.hk")
    sign_in user

    get "/api/locations/not_a_real_key"

    expect(response).to have_http_status(:not_found)
  end

  it "returns closest campus location for coordinates" do
    user = create_user(email: "api_closest_user@cuhk.edu.hk")
    sign_in user

    get "/api/locations/closest", params: { lat: 22.4196, lng: 114.2069 }

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body)
    expect(payload["key"]).to be_present
    expect(payload["distance"]).to be_a(Numeric)
  end
end
