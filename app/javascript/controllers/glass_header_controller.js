import { Controller } from "@hotwired/stimulus"

// LOGIC FOR GLASS HEADERS
// Shrinks the floating pill header width on scroll (items index glass nav).
export default class extends Controller {
  connect() {
    this._onScroll = this._onScroll.bind(this)
    window.addEventListener("scroll", this._onScroll, { passive: true })
    this._onScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this._onScroll)
  }

  _onScroll() {
    const y = window.scrollY || document.documentElement.scrollTop
    this.element.classList.toggle("site-header--floating-scrolled", y > 48)
  }
}
