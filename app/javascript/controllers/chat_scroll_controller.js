import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.visibility = "hidden"

    requestAnimationFrame(() => {
      this.scrollToBottom()
      this.element.style.visibility = "visible"
    })

    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
    })

    this.observer.observe(this.element, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
