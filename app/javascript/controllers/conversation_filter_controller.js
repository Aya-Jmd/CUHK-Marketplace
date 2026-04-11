import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "thread", "empty"]
  static values = { currentConversationId: Number }

  connect() {
    this.filter()
    this.syncActiveThread()
    this.observer = new MutationObserver(() => {
      this.filter()
      this.syncActiveThread()
    })
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  filter() {
    const query = this.hasInputTarget ? this.inputTarget.value.trim().toLowerCase() : ""
    let visibleCount = 0

    this.threadTargets.forEach((thread) => {
      const haystack = (thread.dataset.searchContent || "").toLowerCase()
      const matches = query === "" || haystack.includes(query)

      thread.hidden = !matches
      if (matches) visibleCount += 1
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.hidden = visibleCount > 0
    }
  }

  syncActiveThread() {
    if (!this.hasCurrentConversationIdValue) return

    const activeId = String(this.currentConversationIdValue)

    this.threadTargets.forEach((thread) => {
      thread.classList.toggle("is-active", thread.dataset.conversationId === activeId)
    })
  }
}
