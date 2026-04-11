module ConversationsHelper
  def conversation_thread_preview(conversation)
    last_message = conversation.last_message
    return "No messages yet." if last_message.blank?

    if last_message.offer_update_notice?
      "Offer updated to #{display_price(last_message.offer_update_amount_hkd)}"
    elsif last_message.marketplace_notice?
      case last_message.marketplace_notice_type
      when "offer_accepted"
        "Offer accepted"
      when "offer_cancelled"
        "Transaction cancelled"
      when "offer_completed"
        "Item sold"
      else
        truncate(last_message.content, length: 42)
      end
    else
      truncate(last_message.content, length: 42)
    end
  end

  def conversation_thread_search_content(conversation, user)
    last_message = conversation.last_message

    [
      conversation.other_user_for(user)&.display_name,
      conversation.item.title,
      last_message&.user&.display_name,
      conversation_thread_preview(conversation)
    ].compact.join(" ").squish.downcase
  end
end
