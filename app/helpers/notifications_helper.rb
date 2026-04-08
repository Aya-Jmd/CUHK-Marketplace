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
    offer = notification.notifiable if notification.notifiable.is_a?(Offer)
    item = notification.notifiable if notification.notifiable.is_a?(Item)
    report = notification.notifiable if notification.notifiable.is_a?(ItemReport)

    case notification.action
    when "offer_created", "offer_updated", "offer_accepted", "offer_declined", "offer_completed"
      profile_path
    when "offer_cancelled"
      offer&.item.present? ? item_path(offer.item) : profile_path
    when "offer_withdrawn"
      item.present? ? item_path(item) : profile_path
    when "item_report_created"
      report&.item.present? ? item_path(report.item) : profile_path
    when "item_report_resolved"
      user_path(notification.actor)
    else
      profile_path
    end
  end

  def notification_mark_as_read_path(notification)
    mark_as_read_notification_path(notification, redirect_to: notification_destination_path(notification))
  end
end
