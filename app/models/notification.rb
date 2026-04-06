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
    # This sends data to the specific user's channel
    ActionCable.server.broadcast(
      "notifications_user_#{recipient_id}",
      { 
        message: "#{actor.email} #{action} your item.",
        count: recipient.notifications.unread.count 
      }
    )
  end
end