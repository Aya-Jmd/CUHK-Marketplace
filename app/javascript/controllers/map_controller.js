import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { lat: Number, lng: Number }

  connect() {
    console.log("Map controller connected!")  // MUST SEE THIS IN CONSOLE

    const map = new maplibregl.Map({
      container: this.element.id,
      style: "https://demotiles.maplibre.org/style.json",
      center: [this.lngValue, this.latValue],
      zoom: 15
    })

    new maplibregl.Marker()
      .setLngLat([this.lngValue, this.latValue])
      .addTo(map)
  }
}

console.log("Map controller connected");