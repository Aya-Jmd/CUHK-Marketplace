import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewport", "track", "thumb"]

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
    const maxScrollTop = Math.max(viewport.scrollHeight - viewport.clientHeight, 0)
    const hasOverflow = maxScrollTop > 0

    this.element.classList.toggle("is-scrollable", hasOverflow)
    track.hidden = !hasOverflow

    if (!hasOverflow) {
      thumb.style.height = ""
      thumb.style.transform = ""
      return
    }

    const trackHeight = track.clientHeight
    const thumbHeight = Math.max((viewport.clientHeight / viewport.scrollHeight) * trackHeight, 28)
    const maxThumbOffset = Math.max(trackHeight - thumbHeight, 0)
    const scrollRatio = maxScrollTop === 0 ? 0 : viewport.scrollTop / maxScrollTop
    const thumbOffset = maxThumbOffset * scrollRatio

    thumb.style.height = `${thumbHeight}px`
    thumb.style.transform = `translateY(${thumbOffset}px)`
  }

  thumbPointerDown(event) {
    event.preventDefault()
    event.stopPropagation()

    const thumbHeight = this.thumbTarget.getBoundingClientRect().height

    this.dragState = {
      pointerId: event.pointerId,
      startClientY: event.clientY,
      startScrollTop: this.viewportTarget.scrollTop,
      maxScrollTop: Math.max(this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight, 0),
      maxThumbOffset: Math.max(this.trackTarget.clientHeight - thumbHeight, 0)
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

    const trackRect = this.trackTarget.getBoundingClientRect()
    const thumbHeight = this.thumbTarget.getBoundingClientRect().height
    const maxThumbOffset = Math.max(trackRect.height - thumbHeight, 0)
    const targetOffset = Math.min(Math.max(event.clientY - trackRect.top - thumbHeight / 2, 0), maxThumbOffset)
    const maxScrollTop = Math.max(this.viewportTarget.scrollHeight - this.viewportTarget.clientHeight, 0)
    const scrollRatio = maxThumbOffset === 0 ? 0 : targetOffset / maxThumbOffset

    this.viewportTarget.scrollTop = maxScrollTop * scrollRatio
    this.updateScrollbar()
  }

  pointerMove(event) {
    if (!this.dragState || event.pointerId !== this.dragState.pointerId) {
      return
    }

    event.preventDefault()

    const deltaY = event.clientY - this.dragState.startClientY
    const scrollRatio = this.dragState.maxThumbOffset === 0 ? 0 : deltaY / this.dragState.maxThumbOffset
    const nextScrollTop = this.dragState.startScrollTop + (this.dragState.maxScrollTop * scrollRatio)

    this.viewportTarget.scrollTop = Math.min(Math.max(nextScrollTop, 0), this.dragState.maxScrollTop)
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
}
