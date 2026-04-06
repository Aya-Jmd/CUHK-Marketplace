class Offer < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  validates :price, presence: true, numericality: { greater_than: 0 }

  # Automatically create the anti-scam code right before saving to the DB
  before_create :generate_meetup_code
  after_create :notify_seller

  private
  def notify_seller
    # Don't notify if the user is somehow making an offer on their own item
    return if buyer == seller

    Notification.create(
      recipient: seller,
      actor: buyer,
      action: "made an offer on",
      notifiable: self
    )
  end

  def generate_meetup_code
    # Generates a random 4-digit string
    self.meetup_code = format('%04d', rand(10000))
  end
end