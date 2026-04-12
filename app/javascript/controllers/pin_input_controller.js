import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["digit", "hidden"]

  connect() {
    this.updateHiddenField()
  }

  handleInput(event) {
    const input = event.target
    const index = this.digitTargets.indexOf(input)
    const numbers = this.extractDigits(input.value, this.digitTargets.length - index)

    if (numbers.length === 0) {
      input.value = ""
      this.updateHiddenField()
      return
    }

    this.fillDigitsFrom(index, numbers)
    this.focusNextField(index + numbers.length)
    this.updateHiddenField()
  }

  handleKeydown(event) {
    const input = event.target
    const index = this.digitTargets.indexOf(input)

    if (event.key === "Backspace" && input.value === "") {
      if (index > 0) {
        event.preventDefault()
        this.digitTargets[index - 1].value = ""
        this.digitTargets[index - 1].focus()
      }
      this.updateHiddenField()
      return
    }

    if (event.key === "ArrowLeft" && index > 0) {
      event.preventDefault()
      this.digitTargets[index - 1].focus()
      return
    }

    if (event.key === "ArrowRight" && index < this.digitTargets.length - 1) {
      event.preventDefault()
      this.digitTargets[index + 1].focus()
      return
    }

    if (event.key === "Backspace" || event.key === "Delete") {
      setTimeout(() => this.updateHiddenField(), 0)
    }
  }

  handlePaste(event) {
    event.preventDefault()
    const index = this.digitTargets.indexOf(event.target)
    const pasteData = (event.clipboardData || window.clipboardData).getData("text")
    const numbers = this.extractDigits(pasteData, this.digitTargets.length - index)

    if (numbers.length === 0) {
      return
    }

    this.fillDigitsFrom(index, numbers)
    this.focusNextField(index + numbers.length)
    this.updateHiddenField()
  }

  handleFocus(event) {
    event.target.select()
  }

  handleSubmit(event) {
    this.updateHiddenField()

    if (!new RegExp(`^\\d{${this.digitTargets.length}}$`).test(this.hiddenTarget.value)) {
      event.preventDefault()
      this.focusNextField(0)
    }
  }

  updateHiddenField() {
    const pin = this.digitTargets.map((input) => input.value).join("")
    this.hiddenTarget.value = pin
  }

  extractDigits(value, limit) {
    return value.replace(/\D/g, "").slice(0, limit).split("")
  }

  fillDigitsFrom(startIndex, numbers) {
    numbers.forEach((digit, offset) => {
      const input = this.digitTargets[startIndex + offset]

      if (input) {
        input.value = digit
      }
    })
  }

  focusNextField(preferredIndex) {
    const nextEmptyIndex = this.digitTargets.findIndex(
      (input, index) => index >= preferredIndex && input.value === ""
    )
    const targetIndex = nextEmptyIndex === -1 ? Math.min(preferredIndex, this.digitTargets.length - 1) : nextEmptyIndex
    const target = this.digitTargets[targetIndex]

    if (target) {
      target.focus()
    }
  }
}
