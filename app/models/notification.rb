class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  # Default to unread notifications first
  scope :unread, -> { where(read_at: nil) }

  # After saving to the DB, broadcast to the user's specific channel
  after_create_commit :broadcast_to_recipient

  private

  def broadcast_to_recipient
    ActionCable.server.broadcast(
      "notifications_user_#{recipient_id}",
      notification_payload.merge(count: recipient.notifications.unread.count)
    )
  end

  def notification_payload
    {
      action: action,
      actor_name: actor.display_name,
      item_name: item_name,
      offer_price_hkd: offer_record&.price
    }
  end

  def offer_record
    notifiable if notifiable.is_a?(Offer)
  end

  def item_name
    offer_record&.item&.title || "your item"
  end
end
