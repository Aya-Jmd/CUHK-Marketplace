import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "minInput", "maxInput", "label"]
  static values = {
    min: Number,
    max: Number,
    currency: String,
    autoSubmit: Boolean
  }

  connect() {
    if (!this.hasSliderTarget || typeof noUiSlider === "undefined") return

    if (this.sliderTarget.noUiSlider) {
      this.sliderTarget.noUiSlider.destroy()
    }

    const [startMin, startMax] = this.clampedRange(
      this.numberOrFallback(this.minInputTarget.value, this.minValue),
      this.numberOrFallback(this.maxInputTarget.value, this.maxValue)
    )

    noUiSlider.create(this.sliderTarget, {
      start: [startMin, startMax],
      connect: true,
      range: { min: this.minValue, max: this.maxValue },
      step: 1
    })

    this.sliderTarget.noUiSlider.on("update", (values) => {
      const min = Math.round(values[0])
      const max = Math.round(values[1])

      this.minInputTarget.value = min
      this.maxInputTarget.value = max
      this.labelTarget.textContent = this.currencyFormatter().format(min) + " - " + this.currencyFormatter().format(max)
    })

    if (this.autoSubmitValue) {
      this.sliderTarget.noUiSlider.on("change", () => {
        this.element.closest("form")?.requestSubmit()
      })
    }
  }

  disconnect() {
    if (this.hasSliderTarget && this.sliderTarget.noUiSlider) {
      this.sliderTarget.noUiSlider.destroy()
    }
  }

  clampedRange(min, max) {
    const lower = Math.min(Math.max(min, this.minValue), this.maxValue)
    const upper = Math.min(Math.max(max, this.minValue), this.maxValue)
    return lower <= upper ? [lower, upper] : [upper, lower]
  }

  numberOrFallback(value, fallback) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
  }

  currencyFormatter() {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currencyValue,
      maximumFractionDigits: 0
    })
  }
}
