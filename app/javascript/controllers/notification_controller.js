import { Controller } from "@hotwired/stimulus"
// Use the mapped name 'channels/consumer' instead of the relative path '../channels/consumer'
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["badge", "toast"]
  static values = { currencyCode: String }

  connect() {
    console.log("Notification controller is connected and working!")
    
    this.subscription = consumer.subscriptions.create("NotificationsChannel", {
      connected: () => { console.log("Connected to NotificationsChannel") },
      disconnected: () => { console.log("Disconnected from NotificationsChannel") },
      received: (data) => {
        console.log("Incoming Notification!", data)
        
        if (this.hasBadgeTarget) {
          this.badgeTarget.textContent = data.count
          this.badgeTarget.classList.remove("hidden")
        }

        if (this.hasToastTarget) {
          this.toastTarget.textContent = this.buildMessage(data)
          this.toastTarget.classList.remove("hidden")
          
          setTimeout(() => {
            this.toastTarget.classList.add("hidden")
          }, 5000)
        }
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  buildMessage(data) {
    const actorName = data.actor_name || "Someone"
    const itemName = data.item_name || "your item"

    switch (data.action) {
      case "offer_created":
      case "made an offer on":
        return `${actorName} has made an offer of ${this.formatPrice(data.offer_price_hkd)} for your item ${itemName}!`
      case "offer_declined":
      case "declined your offer for":
        return `${actorName} rejected your offer for the item ${itemName}.`
      case "offer_accepted":
      case "accepted your offer for":
        return `${actorName} accepted your offer for the item ${itemName}. See your dashboard for the confirmation pin!`
      case "offer_cancelled":
      case "cancelled the transaction for":
        return `${actorName} cancelled the transaction for the item ${itemName}.`
      case "offer_completed":
      case "confirmed the sale of":
        return `${actorName} confirmed the sale of the item ${itemName}.`
      default:
        return data.message || `${actorName} ${data.action || "sent a notification"}.`
    }
  }

  formatPrice(amountHkd) {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currencyCodeValue || "HKD",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(Number(amountHkd || 0))
  }
}
