require "rails_helper"

RSpec.describe Category, type: :model do
  subject(:category) { described_class.new(name: "Textbook") }

  it "is valid with a unique name" do
    expect(category).to be_valid
  end

  it "requires a name" do
    category.name = nil

    expect(category).not_to be_valid
    expect(category.errors[:name]).to include("can't be blank")
  end

  it "requires the name to be unique" do
    described_class.create!(name: "Textbook")

    expect(category).not_to be_valid
    expect(category.errors[:name]).to include("has already been taken")
  end

  it "sorts categories alphabetically with Other last" do
    book = described_class.create!(name: "Book")
    other = described_class.create!(name: "Other")
    textbook = described_class.create!(name: "Textbook")

    expect(described_class.sorted_for_dropdown).to eq([ book, textbook, other ])
  end
end
