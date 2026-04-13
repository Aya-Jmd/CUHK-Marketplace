import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.tagName !== "SELECT" || this.element.multiple || this.element.size > 1) return

    this.select = this.element
    this.selectClassNames = this.select.className
    this.optionButtons = []

    this.hydrateExistingUi()
    if (!this.wrapperElement) this.build()

    this.bind()
    this.refresh()
  }

  disconnect() {
    this.unbind()
  }

  build() {
    this.select.classList.add("enhanced-select__native")
    this.select.tabIndex = -1

    this.wrapperElement = document.createElement("div")
    this.wrapperElement.className = "enhanced-select"

    this.triggerElement = document.createElement("button")
    this.triggerElement.type = "button"
    this.triggerElement.className = ["enhanced-select__trigger", this.selectClassNames].filter(Boolean).join(" ")
    this.triggerElement.setAttribute("aria-haspopup", "listbox")

    this.labelElement = document.createElement("span")
    this.labelElement.className = "enhanced-select__label"
    this.triggerElement.append(this.labelElement)

    this.menuElement = document.createElement("div")
    this.menuElement.className = "enhanced-select__menu"
    this.menuElement.setAttribute("role", "listbox")
    this.menuElement.hidden = true

    if (this.select.id) {
      this.menuElement.id = `${this.select.id}-menu`
      this.triggerElement.setAttribute("aria-controls", this.menuElement.id)
    }

    this.wrapperElement.append(this.triggerElement, this.menuElement)
    this.select.insertAdjacentElement("afterend", this.wrapperElement)
  }

  hydrateExistingUi() {
    const existingWrapper = this.select.nextElementSibling
    if (!existingWrapper || !existingWrapper.classList.contains("enhanced-select")) return

    this.wrapperElement = existingWrapper
    this.triggerElement = existingWrapper.querySelector(".enhanced-select__trigger")
    this.labelElement = existingWrapper.querySelector(".enhanced-select__label")
    this.menuElement = existingWrapper.querySelector(".enhanced-select__menu")
  }

  bind() {
    if (this.isBound) return

    this.handleTriggerClick = this.toggle.bind(this)
    this.handleTriggerKeydown = this.onTriggerKeydown.bind(this)
    this.handleMenuClick = this.onMenuClick.bind(this)
    this.handleMenuKeydown = this.onMenuKeydown.bind(this)
    this.handleDocumentPointerDown = this.onDocumentPointerDown.bind(this)
    this.handleSelectChange = this.refresh.bind(this)
    this.handleWindowResize = this.close.bind(this)
    this.handleFormReset = this.onFormReset.bind(this)

    this.triggerElement.addEventListener("click", this.handleTriggerClick)
    this.triggerElement.addEventListener("keydown", this.handleTriggerKeydown)
    this.menuElement.addEventListener("click", this.handleMenuClick)
    this.menuElement.addEventListener("keydown", this.handleMenuKeydown)
    document.addEventListener("pointerdown", this.handleDocumentPointerDown)
    window.addEventListener("resize", this.handleWindowResize)
    this.select.addEventListener("change", this.handleSelectChange)

    this.formElement = this.select.form
    if (this.formElement) {
      this.formElement.addEventListener("reset", this.handleFormReset)
    }

    this.bindLabels()
    this.isBound = true
  }

  unbind() {
    if (!this.isBound) return

    this.triggerElement.removeEventListener("click", this.handleTriggerClick)
    this.triggerElement.removeEventListener("keydown", this.handleTriggerKeydown)
    this.menuElement.removeEventListener("click", this.handleMenuClick)
    this.menuElement.removeEventListener("keydown", this.handleMenuKeydown)
    document.removeEventListener("pointerdown", this.handleDocumentPointerDown)
    window.removeEventListener("resize", this.handleWindowResize)
    this.select.removeEventListener("change", this.handleSelectChange)

    if (this.formElement) {
      this.formElement.removeEventListener("reset", this.handleFormReset)
    }

    this.unbindLabels()
    this.isBound = false
  }

  bindLabels() {
    this.labelHandlers = new Map()
    if (!this.select.id) return

    const escapedId = this.escapeSelector(this.select.id)
    document.querySelectorAll(`label[for="${escapedId}"]`).forEach((label) => {
      const handler = (event) => {
        event.preventDefault()
        this.triggerElement.focus()
      }

      this.labelHandlers.set(label, handler)
      label.addEventListener("click", handler)
    })
  }

  unbindLabels() {
    this.labelHandlers?.forEach((handler, label) => {
      label.removeEventListener("click", handler)
    })
    this.labelHandlers?.clear()
  }

  refresh() {
    const selectedOption = this.select.selectedOptions[0] || this.select.options[0]
    this.labelElement.textContent = selectedOption ? selectedOption.textContent.trim() : ""
    this.triggerElement.disabled = this.select.disabled
    this.triggerElement.setAttribute("aria-expanded", String(this.isOpen()))

    this.menuElement.innerHTML = ""
    this.optionButtons = []

    Array.from(this.select.options).forEach((option, index) => {
      const optionButton = document.createElement("button")
      optionButton.type = "button"
      optionButton.className = "enhanced-select__option"
      optionButton.dataset.enhancedSelectIndex = String(index)
      optionButton.setAttribute("role", "option")
      optionButton.setAttribute("aria-selected", String(option.selected))
      optionButton.textContent = option.textContent.trim()
      optionButton.disabled = option.disabled

      if (option.selected) optionButton.classList.add("is-selected")
      if (option.disabled) optionButton.classList.add("is-disabled")

      this.menuElement.append(optionButton)
      this.optionButtons.push(optionButton)
    })
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open(focusIndex = null) {
    if (this.select.disabled) return

    this.wrapperElement.classList.add("is-open")
    this.menuElement.hidden = false
    this.triggerElement.setAttribute("aria-expanded", "true")

    if (focusIndex !== null) {
      this.focusOption(focusIndex)
    }
  }

  close() {
    this.wrapperElement.classList.remove("is-open")
    this.menuElement.hidden = true
    this.triggerElement.setAttribute("aria-expanded", "false")
  }

  isOpen() {
    return this.wrapperElement.classList.contains("is-open")
  }

  onTriggerKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.open(this.selectedIndex())
      return
    }

    if (event.key === "ArrowUp") {
      event.preventDefault()
      this.open(this.selectedIndex())
      return
    }

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault()
      this.toggle()
      return
    }

    if (event.key === "Escape") {
      this.close()
    }
  }

  onMenuClick(event) {
    const optionButton = event.target.closest(".enhanced-select__option")
    if (!optionButton || optionButton.disabled) return

    this.selectOption(Number(optionButton.dataset.enhancedSelectIndex))
  }

  onMenuKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
      this.triggerElement.focus()
      return
    }

    if (event.key === "Tab") {
      this.close()
      return
    }

    const currentIndex = this.optionButtons.indexOf(document.activeElement)
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.focusOption(currentIndex + 1)
      return
    }

    if (event.key === "ArrowUp") {
      event.preventDefault()
      this.focusOption(currentIndex - 1)
      return
    }

    if (event.key === "Home") {
      event.preventDefault()
      this.focusOption(0)
      return
    }

    if (event.key === "End") {
      event.preventDefault()
      this.focusOption(this.optionButtons.length - 1)
      return
    }

    if (event.key === "Enter" || event.key === " ") {
      const optionButton = document.activeElement.closest(".enhanced-select__option")
      if (!optionButton || optionButton.disabled) return

      event.preventDefault()
      this.selectOption(Number(optionButton.dataset.enhancedSelectIndex))
    }
  }

  onDocumentPointerDown(event) {
    if (!this.wrapperElement.contains(event.target)) {
      this.close()
    }
  }

  onFormReset() {
    window.requestAnimationFrame(() => this.refresh())
  }

  selectOption(index) {
    const option = this.select.options[index]
    if (!option || option.disabled) return

    const previousIndex = this.select.selectedIndex
    this.select.selectedIndex = index
    this.refresh()
    this.close()
    this.triggerElement.focus()

    if (previousIndex !== index) {
      this.select.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }

  focusOption(index) {
    if (!this.optionButtons.length) return

    const normalizedIndex = this.normalizedEnabledIndex(index)
    const optionButton = this.optionButtons[normalizedIndex]
    optionButton?.focus()
  }

  normalizedEnabledIndex(index) {
    const enabledButtons = this.optionButtons.filter((button) => !button.disabled)
    if (!enabledButtons.length) return 0

    const safeIndex = Math.max(0, Math.min(index, this.optionButtons.length - 1))
    const forwardMatch = this.optionButtons.slice(safeIndex).find((button) => !button.disabled)
    if (forwardMatch) return this.optionButtons.indexOf(forwardMatch)

    const backwardMatch = this.optionButtons.slice(0, safeIndex).reverse().find((button) => !button.disabled)
    return backwardMatch ? this.optionButtons.indexOf(backwardMatch) : this.optionButtons.indexOf(enabledButtons[0])
  }

  selectedIndex() {
    const selectedIndex = this.select.selectedIndex
    return selectedIndex >= 0 ? selectedIndex : 0
  }

  escapeSelector(value) {
    if (window.CSS && typeof window.CSS.escape === "function") {
      return window.CSS.escape(value)
    }

    return value.replace(/([ #;?%&,.+*~':"!^$[\]()=>|/@])/g, "\\$1")
  }
}
