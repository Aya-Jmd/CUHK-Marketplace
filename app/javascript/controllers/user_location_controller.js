import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]
  static values = {
    sellerLat: Number,
    sellerLng: Number
  }

  locateMe() {
    if (!navigator.geolocation) {
      this.outputTarget.textContent = "Geolocation not supported."
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude
        const lng = position.coords.longitude

        this.userLocation = { lat, lng }

        // map is created by map-display controller
        const map = this.element._leaflet_map
        if (!map) 
        {
          this.outputTarget.textContent = "Map not ready yet."
          return
        }
        
        if (this.userMarker) {
          this.userMarker.remove()
        }

        this.userMarker = L.marker([lat, lng])
          .addTo(map)
          .bindPopup("📍 You are here")
          .openPopup()

        map.setView([lat, lng], 16)

        this.outputTarget.textContent = "📍 Your location detected."
      },
      () => {
        this.outputTarget.textContent = "Location permission denied."
      }
    )
  }

  toggleDistance() {
    if (!this.userLocation) {
      this.outputTarget.textContent = "Please locate yourself first."
      return
    }

    const dist = this.haversine(
      this.userLocation.lat,
      this.userLocation.lng,
      this.sellerLatValue,
      this.sellerLngValue
    )

    this.outputTarget.textContent =
      `📏 Distance to pickup: ${dist.toFixed(2)} km`
  }

  haversine(lat1, lon1, lat2, lon2) {
    const R = 6371
    const toRad = (v) => v * Math.PI / 180
    const dLat = toRad(lat2 - lat1)
    const dLon = toRad(lon2 - lon1)

    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) ** 2

    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  }
}