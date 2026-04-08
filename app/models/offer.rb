class Offer < ApplicationRecord
  belongs_to :item
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"

  # ADD THIS EXACT LINE: It tells Rails about our state machine!
  enum :status, { pending: "pending", accepted: "accepted", declined: "declined", completed: "completed", failed: "failed" }

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :buyer_id, uniqueness: { scope: :item_id }

  validate :buyer_cannot_be_seller
  validate :item_must_accept_offers, on: :create

  # Automatically create the anti-scam code right before saving to the DB
  before_create :generate_meetup_code

  # Trigger the notification AFTER saving to the DB
  after_create_commit :notify_seller

  def editable_by_buyer?(user)
    buyer == user &&
      item.status == "available" &&
      !item.removed? &&
      !seller&.banned? &&
      (pending? || declined? || failed?)
  end

  def withdrawable_by_buyer?(user)
    buyer == user && (pending? || declined? || failed?)
  end

  private

  def buyer_cannot_be_seller
    return unless buyer_id.present? && buyer_id == seller_id

    errors.add(:buyer, "cannot make an offer on their own item")
  end

  def item_must_accept_offers
    return if item.blank?
    return if item.status == "available" && !item.removed? && !seller&.banned?

    errors.add(:item, "is not accepting offers")
  end

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
  end
end
