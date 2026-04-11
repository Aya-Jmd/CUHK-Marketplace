import { Controller } from "@hotwired/stimulus"
// Use the mapped name 'channels/consumer' instead of the relative path '../channels/consumer'
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      received: (data) => {
        if (this.hasBadgeTarget) {
          this.updateBadge(data.count)
        }
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  updateBadge(count) {
    const unreadCount = Number(count) || 0

    this.badgeTarget.textContent = unreadCount > 99 ? "99+" : unreadCount
    this.badgeTarget.hidden = unreadCount <= 0
  }
}
