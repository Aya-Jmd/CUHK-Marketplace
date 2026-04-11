import { Controller } from "@hotwired/stimulus"

// LOGIC FOR GLASS HEADERS
// Shrinks the floating pill header width on scroll (items index glass nav).
export default class extends Controller {
  connect() {
    this.lastScrollY = window.scrollY || document.documentElement.scrollTop || 0
    this._onScroll = this._onScroll.bind(this)
    window.addEventListener("scroll", this._onScroll, { passive: true })
    this._onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
  }

  _onScroll() {
    const y = window.scrollY || document.documentElement.scrollTop || 0
    const delta = y - this.lastScrollY
    const nearTop = y <= 12
    const scrollingDown = delta > 6
    const scrollingUp = delta < -6

    this.element.classList.toggle("site-header--floating-scrolled", y > 48)

    if (nearTop) {
      this.element.classList.remove("site-header--hidden")
    } else if (scrollingDown && y > 120) {
      this.element.classList.add("site-header--hidden")
    } else if (scrollingUp) {
      this.element.classList.remove("site-header--hidden")
    }

    this.lastScrollY = y
  }
}
