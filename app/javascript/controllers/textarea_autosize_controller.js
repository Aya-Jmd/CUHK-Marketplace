import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.resize()
  }

  resize() {
    if (!this.hasInputTarget) return

    const field = this.inputTarget
    field.style.height = "auto"

    const computedStyle = window.getComputedStyle(field)
    const maxHeight = Number.parseFloat(computedStyle.maxHeight)
    const nextHeight = field.scrollHeight

    if (Number.isFinite(maxHeight) && maxHeight > 0) {
      field.style.height = `${Math.min(nextHeight, maxHeight)}px`
      field.style.overflowY = nextHeight > maxHeight ? "auto" : "hidden"
      return
    }

    field.style.height = `${nextHeight}px`
    field.style.overflowY = "hidden"
  }
}
