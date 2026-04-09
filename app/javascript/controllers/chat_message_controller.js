import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const currentUserId = document.body.dataset.currentUserId
    const messageUserId = this.element.dataset.messageUserId

    if (currentUserId && messageUserId && currentUserId === messageUserId) {
      this.element.classList.add("chat-message--mine")
    } else {
      this.element.classList.remove("chat-message--mine")
    }
  }
}
