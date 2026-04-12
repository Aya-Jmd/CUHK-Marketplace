require "rails_helper"
require "base64"

RSpec.describe "Error pages", type: :request do
  it "renders the custom 404 page for unknown routes" do
    get "/admin/setup"

    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:not_found)
    expect(document.at_css(".error-card")).to be_present
    expect(document.at_css(".site-header")).not_to be_present
    expect(response.body).to include("Page not found")
    expect(response.body).to include("Back to marketplace")
  end

  it "returns a clean 404 for unknown image-like routes" do
    get "/this-image-does-not-exist.jpg"

    expect(response).to have_http_status(:not_found)
  end

  it "does not route active storage image requests through the custom 404 handler" do
    college = create_college(name: "Chung Chi")
    user = create_user(email: "images@example.com", college:)
    item = create_item(user:, college:, title: "Photo listing")

    png_data = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF9sAAAAASUVORK5CYII=")
    item.images.attach(
      io: StringIO.new(png_data),
      filename: "tiny.png",
      content_type: "image/png"
    )

    get rails_blob_path(item.images.first, only_path: true)

    expect(response).not_to have_http_status(:not_found)
    expect(response).not_to have_http_status(:internal_server_error)
  end
end
