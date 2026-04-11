class Message < ApplicationRecord
  MARKETPLACE_NOTICE_PREFIX = "__marketplace_notice__:".freeze
  OFFER_UPDATE_NOTICE_PREFIX = "__marketplace_offer_notice__:".freeze
  NOTICE_DELIMITER = "::".freeze

  belongs_to :conversation, touch: true
  belongs_to :user

  validates :content, presence: true

  # The Turbo Streams Magic
  after_create_commit -> { broadcast_append_to self.conversation, target: "messages" }
  after_create_commit :broadcast_inbox_updates

  def self.offer_update_notice_content(amount_hkd)
    "#{MARKETPLACE_NOTICE_PREFIX}offer_updated#{NOTICE_DELIMITER}#{amount_hkd.to_d.to_s("F")}"
  end

  def self.offer_status_notice_content(status)
    "#{MARKETPLACE_NOTICE_PREFIX}#{status}"
  end

  def marketplace_notice?
    content.to_s.start_with?(MARKETPLACE_NOTICE_PREFIX) || offer_update_notice?
  end

  def marketplace_notice_type
    if content.to_s.start_with?(MARKETPLACE_NOTICE_PREFIX)
      content.delete_prefix(MARKETPLACE_NOTICE_PREFIX).split(NOTICE_DELIMITER, 2).first
    elsif content.to_s.start_with?(OFFER_UPDATE_NOTICE_PREFIX)
      "offer_updated"
    end
  end

  def offer_update_notice?
    marketplace_notice_type == "offer_updated"
  end

  def offer_update_amount_hkd
    return unless offer_update_notice?

    raw_amount =
      if content.to_s.start_with?(MARKETPLACE_NOTICE_PREFIX)
        content.delete_prefix(MARKETPLACE_NOTICE_PREFIX).split(NOTICE_DELIMITER, 2).second
      else
        content.delete_prefix(OFFER_UPDATE_NOTICE_PREFIX)
      end

    raw_amount.to_d
  rescue ArgumentError
    nil
  end

  private

  def broadcast_inbox_updates
    refreshed_conversation = Conversation.includes(:item, :buyer, :seller, messages: :user).find(conversation_id)

    refreshed_conversation.participants.each do |participant|
      Turbo::StreamsChannel.broadcast_render_to(
        participant,
        :conversation_inbox,
        partial: "conversations/sidebar_update",
        locals: { conversation: refreshed_conversation, user: participant }
      )
    end
  end
end
