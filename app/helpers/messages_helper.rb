module MessagesHelper
  def marketplace_notice_text(message)
    case message.marketplace_notice_type
    when "offer_created", "offer_updated"
      safe_join(
        [
          content_tag(:strong, message.user.display_name),
          " made a ",
          content_tag(:strong, display_price(message.offer_notice_amount_hkd)),
          " offer."
        ]
      )
    when "offer_accepted"
      safe_join([ content_tag(:strong, message.user.display_name), " accepted the offer for this item." ])
    when "offer_declined"
      safe_join([ content_tag(:strong, message.user.display_name), " declined the offer." ])
    when "offer_withdrawn"
      safe_join([ content_tag(:strong, message.user.display_name), " cancelled the offer." ])
    when "offer_cancelled"
      safe_join([ content_tag(:strong, message.user.display_name), " cancelled the transaction." ])
    when "offer_completed"
      "The transaction has been completed, this item is sold."
    else
      message.content
    end
  end
end
