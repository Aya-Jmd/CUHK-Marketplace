require "rails_helper"

RSpec.describe College, type: :model do
  it "generates a slug from the college name" do
    college = College.create!(name: "River College", listing_expiry_days: 30)

    expect(college.slug).to eq("river-college")
  end

  it "preserves an explicit slug" do
    college = College.create!(name: "Custom College", slug: "custom-campus", listing_expiry_days: 30)

    expect(college.slug).to eq("custom-campus")
  end

  it "maps matching college slugs to default campus location keys" do
    college = College.create!(name: "Wu Yee Sun College", listing_expiry_days: 30)

    expect(college.default_location_key).to eq("wu_yee_sun")
  end

  it "falls back to central campus when a college does not have a dedicated location key" do
    college = College.create!(name: "River College", listing_expiry_days: 30)

    expect(college.default_location_key).to eq("campus_central")
  end
end
