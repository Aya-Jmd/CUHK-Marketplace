import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { visibleCount: Number }

  connect() {
    this.updateMaxHeight = this.updateMaxHeight.bind(this)
    this.updateMaxHeight()

    this.resizeObserver = new ResizeObserver(() => this.updateMaxHeight())
    Array.from(this.element.children).forEach((child) => this.resizeObserver.observe(child))
    this.resizeObserver.observe(this.element)

    window.addEventListener("resize", this.updateMaxHeight)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.removeEventListener("resize", this.updateMaxHeight)
  }

  updateMaxHeight() {
    const items = Array.from(this.element.children).filter((child) => child.offsetParent !== null)
    const visibleCount = this.visibleCountValue || items.length

    if (items.length <= visibleCount) {
      this.element.style.maxHeight = ""
      return
    }

    const gap = parseFloat(window.getComputedStyle(this.element).rowGap || window.getComputedStyle(this.element).gap || "0")
    const visibleItems = items.slice(0, visibleCount)
    const totalHeight = visibleItems.reduce((sum, item) => sum + item.getBoundingClientRect().height, 0) + (Math.max(visibleItems.length - 1, 0) * gap)

    this.element.style.maxHeight = `${Math.ceil(totalHeight)}px`
  }
}
