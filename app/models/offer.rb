class Offer < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  validates :price, presence: true, numericality: { greater_than: 0 }

  # Automatically create the anti-scam code right before saving to the DB
  before_create :generate_meetup_code

  private

  def generate_meetup_code
    # Generates a random 4-digit string
    self.meetup_code = format('%04d', rand(10000))
  end
end