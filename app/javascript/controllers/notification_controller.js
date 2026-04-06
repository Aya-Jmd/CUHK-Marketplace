import { Controller } from "@hotwired/stimulus"
// Use the mapped name 'channels/consumer' instead of the relative path '../channels/consumer'
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["badge", "toast"]

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
          this.toastTarget.textContent = data.message
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
}