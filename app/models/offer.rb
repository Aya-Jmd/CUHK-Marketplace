class Offer < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  # ADD THIS EXACT LINE: It tells Rails about our state machine!
  enum :status, { pending: "pending", accepted: "accepted", declined: "declined", completed: "completed", failed: "failed" }

  validates :price, presence: true, numericality: { greater_than: 0 }

  # Automatically create the anti-scam code right before saving to the DB
  before_create :generate_meetup_code

  # Trigger the notification AFTER saving to the DB
  after_create_commit :notify_seller

  # Trigger the notification AFTER status updated
  after_update_commit :notify_buyer_of_status_change, if: :saved_change_to_status?

  private

  def generate_meetup_code
    # Generates a random 4-digit string
    self.meetup_code = format("%04d", rand(10000))
  end

  def notify_seller
    # Don't notify if the user is somehow making an offer on their own item
    return if buyer == seller

    Notification.create(
      recipient: seller,
      actor: buyer,
      action: "offer_created",
      notifiable: self
    )

    OfferMailer.notify_seller(self).deliver_later
  end

  def notify_buyer_of_status_change
    if %w[accepted declined].include?(status)
      OfferMailer.notify_buyer(self).deliver_later
    end
  end
end
