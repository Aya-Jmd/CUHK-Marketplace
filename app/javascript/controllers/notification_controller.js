import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      received: (data) => {
        if (this.hasBadgeTarget) {
          this.updateBadge(data.count)
        }

        this.refreshNotificationsPage()
      }
    })
  }

  disconnect() {
    if (this.refreshTimeout) {
      clearTimeout(this.refreshTimeout)
    }

    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  updateBadge(count) {
    const unreadCount = Number(count) || 0

    this.badgeTarget.textContent = unreadCount > 99 ? "99+" : unreadCount
    this.badgeTarget.hidden = unreadCount <= 0
  }

  refreshNotificationsPage() {
    if (window.location.pathname !== "/notifications") return

    if (this.refreshTimeout) {
      clearTimeout(this.refreshTimeout)
    }

    this.refreshTimeout = window.setTimeout(() => {
      if (window.Turbo?.visit) {
        window.Turbo.visit(window.location.href, { action: "replace" })
      } else {
        window.location.reload()
      }
    }, 150)
  }
}
