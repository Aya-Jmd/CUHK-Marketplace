class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }

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
      offer_price_hkd: offer_price_hkd,
      message: realtime_message
    }
  end

  def offer_record
    notifiable if notifiable.is_a?(Offer)
  end

  def item_record
    notifiable if notifiable.is_a?(Item)
  end

  def item_report_record
    notifiable if notifiable.is_a?(ItemReport)
  end

  def offer_price_hkd
    amount_hkd || offer_record&.price
  end

  def item_name
    offer_record&.item&.title || item_report_record&.item&.title || item_record&.title || "your item"
  end

  def realtime_message
    case action
    when "offer_updated"
      "#{actor.display_name} updated their offer for #{item_name} to #{offer_price_hkd} HKD."
    when "offer_accepted"
      "#{actor.display_name} accepted the offer for #{item_name}."
    when "offer_cancelled"
      "#{actor.display_name} cancelled the transaction for #{item_name}."
    when "offer_completed"
      "#{actor.display_name} completed the transaction for #{item_name}."
    when "offer_withdrawn"
      "#{actor.display_name} has cancelled their offer of #{offer_price_hkd} HKD for item #{item_name}."
    when "item_report_created"
      "#{actor.display_name} reported #{item_name}: #{report_excerpt}"
    when "item_report_resolved"
      "#{actor.display_name} resolved the report for #{item_name}: #{item_report_record&.resolution_summary || 'Resolved'}."
    else
      nil
    end
  end

  def report_excerpt
    text = item_report_record&.message.to_s.squish
    return "No details provided." if text.blank?

    text.length > 90 ? "#{text.first(87)}..." : text
  end
end
