class Message < ApplicationRecord
  OFFER_UPDATE_NOTICE_PREFIX = "__marketplace_offer_notice__:".freeze

  belongs_to :conversation, touch: true
  belongs_to :user

  validates :content, presence: true

  # The Turbo Streams Magic
  after_create_commit -> { broadcast_append_to self.conversation, target: "messages" }
  after_create_commit :broadcast_inbox_updates

  def self.offer_update_notice_content(amount_hkd)
    "#{OFFER_UPDATE_NOTICE_PREFIX}#{amount_hkd.to_d.to_s("F")}"
  end

  def offer_update_notice?
    content.to_s.start_with?(OFFER_UPDATE_NOTICE_PREFIX)
  end

  def offer_update_amount_hkd
    return unless offer_update_notice?

    content.delete_prefix(OFFER_UPDATE_NOTICE_PREFIX).to_d
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
