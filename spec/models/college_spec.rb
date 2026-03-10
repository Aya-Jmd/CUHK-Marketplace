require "rails_helper"

RSpec.describe College, type: :model do
  subject(:college) { described_class.new(name: "New Asia College", listing_expiry_days: 30) }

  it "is valid with a unique name" do
    expect(college).to be_valid
  end

  it "requires a name" do
    college.name = nil

    expect(college).not_to be_valid
    expect(college.errors[:name]).to include("can't be blank")
  end

  it "requires the name to be unique" do
    described_class.create!(name: "New Asia College", listing_expiry_days: 30)

    expect(college).not_to be_valid
    expect(college.errors[:name]).to include("has already been taken")
  end
end
