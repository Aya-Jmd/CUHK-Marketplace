import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "summary"]

  connect() {
    this.emptyText = this.summaryTarget.textContent.trim()
    this.update()
  }

  pick() {
    this.inputTarget.click()
  }

  update() {
    const files = Array.from(this.inputTarget.files || [])

    if (files.length === 0) {
      this.summaryTarget.textContent = this.emptyText
      this.element.classList.remove("has-files")
      return
    }

    if (files.length === 1) {
      this.summaryTarget.textContent = files[0].name
    } else {
      this.summaryTarget.textContent = `${files.length} files selected`
    }

    this.element.classList.add("has-files")
  }
}
