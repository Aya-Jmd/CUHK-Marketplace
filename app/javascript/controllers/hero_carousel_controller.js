import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { interval: { type: Number, default: 6800 } }

  connect() {
    this.index = 0
    this.timer = null
    this.reduceMotionQuery = window.matchMedia("(prefers-reduced-motion: reduce)")

    this.show(this.index)
    this.resume()
  }

  disconnect() {
    this.stop()
  }

  next() {
    this.show(this.index + 1)
    this.restart()
  }

  prev() {
    this.show(this.index - 1)
    this.restart()
  }

  goTo(event) {
    const nextIndex = Number(event.currentTarget.dataset.index)
    if (Number.isNaN(nextIndex)) return

    this.show(nextIndex)
    this.restart()
  }

  pause() {
    this.stop()
  }

  resume() {
    if (this.reduceMotionQuery.matches || this.slideTargets.length < 2 || this.timer) return

    this.timer = window.setInterval(() => {
      this.show(this.index + 1)
    }, this.intervalValue)
  }

  restart() {
    this.stop()
    this.resume()
  }

  show(nextIndex) {
    const total = this.slideTargets.length
    if (total === 0) return

    this.index = (nextIndex + total) % total

    this.slideTargets.forEach((slide, index) => {
      const active = index === this.index
      slide.classList.toggle("is-active", active)
      slide.setAttribute("aria-hidden", String(!active))

      slide.querySelectorAll("a, button").forEach((element) => {
        element.tabIndex = active ? 0 : -1
      })
    })

    this.dotTargets.forEach((dot, index) => {
      const active = index === this.index
      dot.classList.toggle("is-active", active)
      dot.setAttribute("aria-pressed", String(active))
    })
  }

  stop() {
    if (!this.timer) return

    window.clearInterval(this.timer)
    this.timer = null
  }
}
