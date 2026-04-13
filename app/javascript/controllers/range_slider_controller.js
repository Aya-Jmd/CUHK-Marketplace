import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "minInput", "maxInput", "label"]
  static values = {
    min: Number,
    max: Number,
    steps: Array,
    currency: String,
    autoSubmit: Boolean
  }

  connect() {
    if (!this.hasSliderTarget) return

    if (this.sliderTarget.noUiSlider) {
      this.sliderTarget.noUiSlider.destroy()
    }

    const steps = this.normalizedSteps()
    const [startMinIndex, startMaxIndex] = this.clampedIndexes(
      this.indexForMin(steps, this.numberOrFallback(this.minInputTarget.value, steps[0])),
      this.indexForMax(steps, this.numberOrFallback(this.maxInputTarget.value, steps[steps.length - 1])),
      steps.length
    )

    this.applySelection(steps, startMinIndex, startMaxIndex)
    this.sliderTarget.hidden = steps.length < 2

    if (typeof noUiSlider === "undefined" || steps.length < 2) return

    noUiSlider.create(this.sliderTarget, {
      start: [startMinIndex, startMaxIndex],
      connect: true,
      range: { min: 0, max: steps.length - 1 },
      step: 1
    })

    this.sliderTarget.noUiSlider.on("update", (values) => {
      this.applySelection(steps, Number(values[0]), Number(values[1]))
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

  normalizedSteps() {
    const fallbackSteps = [this.minValue, this.maxValue]
    const source = this.hasStepsValue && this.stepsValue.length > 0 ? this.stepsValue : fallbackSteps
    const normalized = [...new Set(source
      .map((value) => this.numberOrFallback(value, null))
      .filter((value) => Number.isFinite(value))
      .map((value) => Number(value.toFixed(2))))]
      .sort((left, right) => left - right)

    return normalized.length > 0 ? normalized : [0]
  }

  clampedIndexes(minIndex, maxIndex, stepsLength) {
    const lower = this.clampedIndex(minIndex, stepsLength)
    const upper = this.clampedIndex(maxIndex, stepsLength)
    return lower <= upper ? [lower, upper] : [upper, lower]
  }

  clampedIndex(index, stepsLength) {
    if (stepsLength <= 1) return 0

    const roundedIndex = Math.round(index)
    return Math.min(Math.max(roundedIndex, 0), stepsLength - 1)
  }

  indexForMin(steps, value) {
    let selectedIndex = 0

    steps.forEach((step, index) => {
      if (step <= value) selectedIndex = index
    })

    return selectedIndex
  }

  indexForMax(steps, value) {
    const selectedIndex = steps.findIndex((step) => step >= value)
    return selectedIndex >= 0 ? selectedIndex : steps.length - 1
  }

  applySelection(steps, minIndex, maxIndex) {
    const [lowerIndex, upperIndex] = this.clampedIndexes(minIndex, maxIndex, steps.length)
    const min = steps[lowerIndex]
    const max = steps[upperIndex]

    this.minInputTarget.value = min.toFixed(2)
    this.maxInputTarget.value = max.toFixed(2)
    this.labelTarget.textContent =
      this.currencyFormatter().format(this.readableDisplayValue(min)) +
      " - " +
      this.currencyFormatter().format(this.readableDisplayValue(max))
  }

  numberOrFallback(value, fallback) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : fallback
  }

  readableDisplayValue(value) {
    if (value <= 0) return 0

    if (value >= 1000) {
      return Math.ceil(value / 10) * 10
    }

    if (value >= 100) {
      return Math.ceil(value / 5) * 5
    }

    return Math.ceil(value)
  }

  currencyFormatter() {
    return new Intl.NumberFormat(undefined, {
      style: "currency",
      currency: this.currencyValue,
      minimumFractionDigits: 0,
      maximumFractionDigits: 2
    })
  }
}
