import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group"]

  connect() {
    this.storageKey = "search-filter-sidebar-state"
    this.toggleHandlers = new Map()
    this.restoreState()
    this.bindGroups()
  }

  disconnect() {
    this.groupTargets.forEach((group) => {
      const handler = this.toggleHandlers.get(group)
      if (handler) group.removeEventListener("toggle", handler)
    })
    this.toggleHandlers.clear()
  }

  bindGroups() {
    this.groupTargets.forEach((group) => {
      const handler = () => this.persistState()
      this.toggleHandlers.set(group, handler)
      group.addEventListener("toggle", handler)
    })
  }

  restoreState() {
    const openKeys = this.readState()
    if (!openKeys) return

    this.groupTargets.forEach((group) => {
      const key = group.dataset.filterStateKey
      group.open = openKeys.includes(key)
    })
  }

  persistState() {
    try {
      const openKeys = this.groupTargets
        .filter((group) => group.open)
        .map((group) => group.dataset.filterStateKey)

      window.localStorage.setItem(this.storageKey, JSON.stringify(openKeys))
    } catch (_error) {
      // Ignore storage failures and fall back to closed-by-default behavior.
    }
  }

  readState() {
    try {
      const raw = window.localStorage.getItem(this.storageKey)
      if (!raw) return null

      const parsed = JSON.parse(raw)
      return Array.isArray(parsed) ? parsed : null
    } catch (_error) {
      return null
    }
  }
}
