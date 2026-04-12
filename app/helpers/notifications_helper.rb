module NotificationsHelper
  def notification_categories
    categories = [
      [ "all", "All" ],
      [ "offers", "Offers" ]
    ]

    if current_user&.admin? || current_user&.college_admin?
      categories += [
        [ "all_reports", "All Reports" ],
        [ "pending_reports", "Pending Reports" ]
      ]
    end

    categories
  end

  def notification_filter_params(category:, show_unread_only:)
    {
      category: category,
      show_unread: show_unread_only ? "1" : "0"
    }
  end

  def notification_category_link_style(selected_category, category)
    active = selected_category == category
    base = "display:inline-flex; align-items:center; gap:8px; padding:10px 4px; border:none; border-bottom:2px solid transparent; color:#475467; text-decoration:none; font-weight:600;"
    return base unless active

    "#{base} border-bottom-color:#d92d20; color:#101828;"
  end

  def notification_count_badge_style
    "display:inline-flex; align-items:center; justify-content:center; min-width:1.4rem; height:1.4rem; padding:0 0.35rem; border-radius:999px; background:#f2f4f7; color:#344054; font-size:0.78rem; font-weight:700;"
  end

  def actionable_report_notification?(notification)
    notification.action == "item_report_created" &&
      notification.notifiable.is_a?(ItemReport) &&
      notification.notifiable.pending?
  end

  def offer_notification?(notification)
    notification.action.to_s.start_with?("offer_")
  end

  def report_notification?(notification)
    notification.action.to_s.start_with?("item_report_")
  end

  def notification_offer_message(notification)
    actor_segment = notification_actor_link(notification)
    item_segment = notification_item_link(notification)
    amount_segment = content_tag(:strong, notification_offer_amount(notification), class: "notification-card__amount")

    case notification.action
    when "offer_created"
      safe_join([ actor_segment, " has made an offer of ", amount_segment, " for ", item_segment, "." ])
    when "offer_updated"
      safe_join([ actor_segment, " updated their offer to ", amount_segment, " for ", item_segment, "." ])
    when "offer_withdrawn"
      safe_join([ actor_segment, " has cancelled their offer of ", amount_segment, " for ", item_segment, "." ])
    when "offer_declined"
      safe_join([ actor_segment, " declined the offer." ])
    when "offer_accepted"
      safe_join([ actor_segment, " accepted your offer for ", item_segment, "." ])
    when "offer_cancelled"
      safe_join([ actor_segment, " cancelled the transaction for ", item_segment, "." ])
    when "offer_completed"
      safe_join([ actor_segment, " confirmed the sale of ", item_segment, "." ])
    else
      notification_message(notification)
    end
  end

  def notification_offer_detail_message(notification)
    case notification.action
    when "offer_created", "offer_updated", "offer_withdrawn"
      "Offer amount: #{notification_offer_amount(notification)}"
    when "offer_accepted"
      "Check your buyer hub for the meetup PIN."
    when "offer_declined"
      "You can make a fresh offer if the listing is still available."
    when "offer_cancelled"
      "The transaction was cancelled and the listing may be available again."
    when "offer_completed"
      "The transaction has been marked as completed."
    end
  end

  def notification_offer_badge_label(notification)
    case notification.action
    when "offer_created" then "New offer"
    when "offer_updated" then "Updated"
    when "offer_withdrawn" then "Withdrawn"
    when "offer_declined" then "Declined"
    when "offer_accepted" then "Accepted"
    when "offer_cancelled" then "Cancelled"
    when "offer_completed" then "Completed"
    end
  end

  def notification_offer_badge_class(notification)
    case notification.action
    when "offer_accepted", "offer_completed"
      "notification-card__badge--resolved"
    when "offer_declined", "offer_cancelled", "offer_withdrawn"
      "notification-card__badge--pending"
    else
      "notification-card__badge--offer"
    end
  end

  def notification_report_message(notification)
    case notification.action
    when "item_report_created"
      safe_join([ notification_actor_link(notification), " reported the item ", notification_item_link(notification), " for review." ])
    when "item_report_resolved"
      safe_join([ notification_actor_link(notification), " resolved the report for ", notification_item_link(notification), "." ])
    else
      notification_message(notification)
    end
  end

  def notification_detail_message(notification)
    report = notification.notifiable if notification.notifiable.is_a?(ItemReport)
    return if report.blank?

    case notification.action
    when "item_report_created"
      "Report message: #{report.message}"
    when "item_report_resolved"
      "Outcome: #{report.resolution_summary}"
    end
  end

  def notification_badge_label(notification)
    return "Resolved" if notification.action == "item_report_resolved"

    report = notification.notifiable if notification.notifiable.is_a?(ItemReport)
    return "Resolved" if notification.action == "item_report_created" && report&.resolved?

    nil
  end

  def notification_badge_style(notification)
    case notification_badge_label(notification)
    when "Resolved"
      "display:inline-flex; align-items:center; gap:6px; background:#ecfdf3; color:#027a48; border:1px solid #abefc6; border-radius:999px; padding:4px 10px; font-size:0.75em; font-weight:700;"
    else
      ""
    end
  end

  def notification_destination_path(notification)
    report = notification.notifiable if notification.notifiable.is_a?(ItemReport)

    case notification.action
    when "offer_created", "offer_updated", "offer_accepted", "offer_declined",
         "offer_completed", "offer_cancelled", "offer_withdrawn"
      dashboard_path(anchor: "dashboard")
    when "item_report_created"
      report&.item.present? ? item_path(report.item) : dashboard_path
    when "item_report_resolved"
      user_path(notification.actor)
    else
      dashboard_path
    end
  end

  def notification_mark_as_read_path(notification)
    mark_as_read_notification_path(notification, redirect_to: notification_destination_path(notification))
  end

  def notification_mark_as_read_redirect_path(notification, destination)
    mark_as_read_notification_path(notification, redirect_to: destination)
  end

  def notification_offer_card_path(notification)
    notification_mark_as_read_redirect_path(notification, notification_destination_path(notification))
  end

  def notification_actor_link(notification)
    actor = notification.actor
    return "Someone" if actor.blank?

    link_to actor.display_name,
      notification_mark_as_read_redirect_path(notification, user_path(actor)),
      data: { turbo_method: :patch },
      class: "notification-card__inline-link"
  end

  def notification_item_link(notification)
    item = notification_item(notification)
    return "your item" if item.blank?

    link_to item.title,
      notification_mark_as_read_redirect_path(notification, item_path(item)),
      data: { turbo_method: :patch },
      class: "notification-card__inline-link"
  end

  def notification_item(notification)
    return notification.notifiable.item if notification.notifiable.is_a?(Offer)
    return notification.notifiable.item if notification.notifiable.is_a?(ItemReport)
    return notification.notifiable if notification.notifiable.is_a?(Item)

    nil
  end

  def notification_offer_amount(notification)
    amount_hkd =
      if notification.notifiable.is_a?(Offer)
        notification.notifiable.price
      else
        notification[:amount_hkd]
      end

    display_price(amount_hkd)
  end

  def notification_standard_message(notification)
    case notification.action
    when "item_report_created", "item_report_resolved"
      notification_report_message(notification)
    else
      link_to notification_message(notification),
        notification_mark_as_read_path(notification),
        data: { turbo_method: :patch },
        class: "notification-card__title-link"
    end
  end
end
