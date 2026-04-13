import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["readView", "editView", "input", "hint", "error"]
  static values = {
    open: Boolean,
    original: String
  }

  connect() {
    this.sync()

    if (this.openValue) {
      this.focusInput()
    }
  }

  open(event) {
    event?.preventDefault()
    this.openValue = true
    this.sync()
    this.focusInput()
  }

  close(event) {
    event?.preventDefault()
    this.openValue = false
    this.resetInput()
    this.sync()
  }

  sync() {
    const isOpen = this.openValue

    this.toggle(this.readViewTarget, !isOpen)
    this.toggle(this.editViewTarget, isOpen)

    if (this.hasHintTarget) {
      this.toggle(this.hintTarget, isOpen)
    }

    if (this.hasErrorTarget) {
      this.toggle(this.errorTarget, isOpen)
    }
  }

  focusInput() {
    if (!this.hasInputTarget) return

    this.inputTarget.focus()
    this.inputTarget.select()
  }

  resetInput() {
    if (!this.hasInputTarget) return

    this.inputTarget.value = this.originalValue
  }

  toggle(element, shouldShow) {
    element.hidden = !shouldShow
    element.setAttribute("aria-hidden", String(!shouldShow))
  }
}
