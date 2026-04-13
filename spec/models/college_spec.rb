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
end
