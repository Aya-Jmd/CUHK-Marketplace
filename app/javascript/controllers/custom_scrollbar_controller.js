import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewport", "track", "thumb"]
  static values = { axis: String }

  connect() {
    this.handleScroll = this.updateScrollbar.bind(this)
    this.handlePointerMove = this.pointerMove.bind(this)
    this.handlePointerUp = this.pointerUp.bind(this)
    this.handleMutations = this.scheduleUpdate.bind(this)

    this.viewportTarget.addEventListener("scroll", this.handleScroll)

    this.mutationObserver = new MutationObserver(this.handleMutations)
    this.mutationObserver.observe(this.viewportTarget, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["class", "hidden", "open", "style"]
    })

    if (window.ResizeObserver) {
      this.resizeObserver = new ResizeObserver(() => {
        this.updateScrollbar()
      })

      this.resizeObserver.observe(this.element)
      this.resizeObserver.observe(this.viewportTarget)
    }

    this.scheduleUpdate()
  }

  disconnect() {
    this.mutationObserver?.disconnect()
    this.resizeObserver?.disconnect()
    this.viewportTarget.removeEventListener("scroll", this.handleScroll)
    window.removeEventListener("pointermove", this.handlePointerMove)
    window.removeEventListener("pointerup", this.handlePointerUp)
    window.removeEventListener("pointercancel", this.handlePointerUp)

    if (this.frame) {
      cancelAnimationFrame(this.frame)
      this.frame = null
    }
  }

  scheduleUpdate() {
    if (this.frame) {
      cancelAnimationFrame(this.frame)
    }

    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.updateScrollbar()
    })
  }

  updateScrollbar() {
    const viewport = this.viewportTarget
    const track = this.trackTarget
    const thumb = this.thumbTarget
    const horizontal = this.isHorizontal()
    const maxScrollPosition = horizontal ?
      Math.max(viewport.scrollWidth - viewport.clientWidth, 0) :
      Math.max(viewport.scrollHeight - viewport.clientHeight, 0)
    const hasOverflow = maxScrollPosition > 0

    this.element.classList.toggle("is-scrollable", hasOverflow)
    track.hidden = !hasOverflow

    if (!hasOverflow) {
      thumb.style.width = ""
      thumb.style.height = ""
      thumb.style.transform = ""
      return
    }

    const trackSize = horizontal ? track.clientWidth : track.clientHeight
    const viewportSize = horizontal ? viewport.clientWidth : viewport.clientHeight
    const contentSize = horizontal ? viewport.scrollWidth : viewport.scrollHeight
    const thumbSize = Math.max((viewportSize / contentSize) * trackSize, 28)
    const maxThumbOffset = Math.max(trackSize - thumbSize, 0)
    const scrollPosition = horizontal ? viewport.scrollLeft : viewport.scrollTop
    const scrollRatio = maxScrollPosition === 0 ? 0 : scrollPosition / maxScrollPosition
    const thumbOffset = maxThumbOffset * scrollRatio

    thumb.style.width = horizontal ? `${thumbSize}px` : ""
    thumb.style.height = horizontal ? "" : `${thumbSize}px`
    thumb.style.transform = horizontal ? `translateX(${thumbOffset}px)` : `translateY(${thumbOffset}px)`
  }

  thumbPointerDown(event) {
    event.preventDefault()
    event.stopPropagation()

    const horizontal = this.isHorizontal()
    const thumbSize = horizontal ?
      this.thumbTarget.getBoundingClientRect().width :
      this.thumbTarget.getBoundingClientRect().height

    this.dragState = {
      pointerId: event.pointerId,
      horizontal,
      startClientPosition: horizontal ? event.clientX : event.clientY,
      startScrollPosition: horizontal ? this.viewportTarget.scrollLeft : this.viewportTarget.scrollTop,
      maxScrollPosition: horizontal ?
        Math.max(this.viewportTarget.scrollWidth - this.viewportTarget.clientWidth, 0) :
        Math.max(this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight, 0),
      maxThumbOffset: horizontal ?
        Math.max(this.trackTarget.clientWidth - thumbSize, 0) :
        Math.max(this.trackTarget.clientHeight - thumbSize, 0)
    }

    this.thumbTarget.setPointerCapture?.(event.pointerId)
    window.addEventListener("pointermove", this.handlePointerMove)
    window.addEventListener("pointerup", this.handlePointerUp)
    window.addEventListener("pointercancel", this.handlePointerUp)
  }

  trackPointerDown(event) {
    if (event.target === this.thumbTarget) {
      return
    }

    event.preventDefault()

    const horizontal = this.isHorizontal()
    const trackRect = this.trackTarget.getBoundingClientRect()
    const thumbSize = horizontal ?
      this.thumbTarget.getBoundingClientRect().width :
      this.thumbTarget.getBoundingClientRect().height
    const trackSize = horizontal ? trackRect.width : trackRect.height
    const trackStart = horizontal ? trackRect.left : trackRect.top
    const pointerPosition = horizontal ? event.clientX : event.clientY
    const maxThumbOffset = Math.max(trackSize - thumbSize, 0)
    const targetOffset = Math.min(Math.max(pointerPosition - trackStart - thumbSize / 2, 0), maxThumbOffset)
    const maxScrollPosition = horizontal ?
      Math.max(this.viewportTarget.scrollWidth - this.viewportTarget.clientWidth, 0) :
      Math.max(this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight, 0)
    const scrollRatio = maxThumbOffset === 0 ? 0 : targetOffset / maxThumbOffset

    if (horizontal) {
      this.viewportTarget.scrollLeft = maxScrollPosition * scrollRatio
    } else {
      this.viewportTarget.scrollTop = maxScrollPosition * scrollRatio
    }
    this.updateScrollbar()
  }

  pointerMove(event) {
    if (!this.dragState || event.pointerId !== this.dragState.pointerId) {
      return
    }

    event.preventDefault()

    const pointerPosition = this.dragState.horizontal ? event.clientX : event.clientY
    const delta = pointerPosition - this.dragState.startClientPosition
    const scrollRatio = this.dragState.maxThumbOffset === 0 ? 0 : delta / this.dragState.maxThumbOffset
    const nextScrollPosition = this.dragState.startScrollPosition + (this.dragState.maxScrollPosition * scrollRatio)

    if (this.dragState.horizontal) {
      this.viewportTarget.scrollLeft = Math.min(Math.max(nextScrollPosition, 0), this.dragState.maxScrollPosition)
    } else {
      this.viewportTarget.scrollTop = Math.min(Math.max(nextScrollPosition, 0), this.dragState.maxScrollPosition)
    }
    this.updateScrollbar()
  }

  pointerUp(event) {
    if (!this.dragState || event.pointerId !== this.dragState.pointerId) {
      return
    }

    this.thumbTarget.releasePointerCapture?.(event.pointerId)
    this.dragState = null
    window.removeEventListener("pointermove", this.handlePointerMove)
    window.removeEventListener("pointerup", this.handlePointerUp)
    window.removeEventListener("pointercancel", this.handlePointerUp)
  }

  isHorizontal() {
    return this.hasAxisValue && this.axisValue === "horizontal"
  }
}
