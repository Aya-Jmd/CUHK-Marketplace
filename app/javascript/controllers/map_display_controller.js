import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    locationName: String,
    title: String
  }

  CUHK_BOUNDS = {
    minLat: 22.4100,
    maxLat: 22.4250,
    minLng: 114.2000,
    maxLng: 114.2150
  }

  connect() {
    this.initMap()
  }

  initMap() {
    if (typeof L === "undefined") {
      setTimeout(() => this.initMap(), 100)
      return
    }

    const lat = this.latValue
    const lng = this.lngValue

    if (!lat || !lng) {
      this.element.innerHTML =
        '<p class="text-muted">No location set for this item</p>'
      return
    }

    const map = L.map(this.element).setView([lat, lng], 16)

    const southWest = L.latLng(
      this.CUHK_BOUNDS.minLat,
      this.CUHK_BOUNDS.minLng
    )
    const northEast = L.latLng(
      this.CUHK_BOUNDS.maxLat,
      this.CUHK_BOUNDS.maxLng
    )
    map.setMaxBounds(southWest, northEast)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "© OpenStreetMap contributors",
      maxZoom: 19
    }).addTo(map)

    const bounds = [
      [this.CUHK_BOUNDS.minLat, this.CUHK_BOUNDS.minLng],
      [this.CUHK_BOUNDS.maxLat, this.CUHK_BOUNDS.maxLng]
    ]

    L.rectangle(bounds, {
      color: "#ff7800",
      weight: 2,
      fill: false,
      dashArray: "5, 5"
    }).addTo(map).bindPopup("CUHK Campus Area")

    const marker = L.marker([lat, lng]).addTo(map)

    const locationDisplay = this.locationNameValue
      ? this.locationNameValue
          .split("_")
          .map(w => w.charAt(0).toUpperCase() + w.slice(1))
          .join(" ")
      : "Pickup location"

    const popupContent = `
      <strong>${this.titleValue || "Item Location"}</strong><br>
      ${locationDisplay}
    `

    marker.bindPopup(popupContent).openPopup()

    // ✅ expose map to other controllers (user-location)
    this.element._leaflet_map = map
  }
}