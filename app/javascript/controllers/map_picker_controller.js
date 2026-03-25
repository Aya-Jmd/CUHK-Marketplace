import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "latInput", "lngInput", "locationNameInput"]
  static values = {
    initialLat: Number,
    initialLng: Number,
    zoom: Number
  }

  // CUHK campus boundaries
  CUHK_BOUNDS = {
    minLat: 22.4100,  // South boundary
    maxLat: 22.4250,  // North boundary  
    minLng: 114.2000, // West boundary
    maxLng: 114.2150  // East boundary
  }

  connect() {
    this.initMap()
  }

  initMap() {
    // Wait for Leaflet to load
    if (typeof L === 'undefined') {
      setTimeout(() => this.initMap(), 100)
      return
    }

    // Default to CUHK central
    const defaultLat = this.initialLatValue || 22.4172
    const defaultLng = this.initialLngValue || 114.2071
    const zoom = this.zoomValue || 16

    // Create map with restricted zoom levels - users can only zoom between 15 and 18
    this.map = L.map(this.mapTarget, {
      minZoom: 15,
      maxZoom: 18
    }).setView([defaultLat, defaultLng], zoom)
    
    // Set max bounds to CUHK area - user cannot pan outside
    const southWest = L.latLng(this.CUHK_BOUNDS.minLat, this.CUHK_BOUNDS.minLng)
    const northEast = L.latLng(this.CUHK_BOUNDS.maxLat, this.CUHK_BOUNDS.maxLng)
    this.map.setMaxBounds(southWest, northEast)
    
    // Disable panning outside bounds (will snap back)
    this.map.on('drag', () => {
      this.map.panInsideBounds(southWest, northEast)
    })

    // Add colorful OpenStreetMap tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Add CUHK boundary overlay (visual guide)
    const bounds = [
      [this.CUHK_BOUNDS.minLat, this.CUHK_BOUNDS.minLng],
      [this.CUHK_BOUNDS.maxLat, this.CUHK_BOUNDS.maxLng]
    ]
    L.rectangle(bounds, { 
      color: "#ff7800", 
      weight: 2,
      fill: false,
      dashArray: "5, 5"
    }).addTo(this.map).bindPopup("CUHK Campus Area")

    // Add markers for all CUHK colleges
    this.addCollegeMarkers()

    // Add marker that can be dragged
    this.marker = L.marker([defaultLat, defaultLng], { draggable: true })
      .addTo(this.map)
      .bindPopup('Drag to set item location within campus')
      .openPopup()

    // Update form fields when marker is dragged
    this.marker.on('dragend', (event) => {
      const position = this.marker.getLatLng()
      if (this.isWithinCampus(position.lat, position.lng)) {
        this.updateFormFields(position.lat, position.lng)
        this.lastValidLat = position.lat
        this.lastValidLng = position.lng
      } else {
        // Reset to last valid position
        this.marker.setLatLng([this.lastValidLat || defaultLat, this.lastValidLng || defaultLng])
        alert('Please select a location within CUHK campus')
      }
    })

    // Update form fields when map is clicked
    this.map.on('click', (event) => {
      const { lat, lng } = event.latlng
      if (this.isWithinCampus(lat, lng)) {
        this.marker.setLatLng([lat, lng])
        this.updateFormFields(lat, lng)
        this.lastValidLat = lat
        this.lastValidLng = lng
      } else {
        alert('Please click within CUHK campus area')
      }
    })

    // Store initial valid position
    if (this.isWithinCampus(defaultLat, defaultLng)) {
      this.lastValidLat = defaultLat
      this.lastValidLng = defaultLng
    }
  }

  addCollegeMarkers() {
    // Fetch all CUHK locations from the server
    fetch('/api/locations/all')
      .then(response => response.json())
      .then(locations => {
        locations.forEach(loc => {
          const marker = L.marker([loc.lat, loc.lng], {
            icon: L.divIcon({
              className: 'cuhk-marker',
              html: '🏛️',
              iconSize: [24, 24],
              popupAnchor: [0, -12]
            })
          }).addTo(this.map)
          
          marker.bindPopup(`
            <strong>${loc.name}</strong><br>
            Click to set location here
          `)
          
          marker.on('click', () => {
            this.marker.setLatLng([loc.lat, loc.lng])
            this.updateFormFields(loc.lat, loc.lng)
            this.map.setView([loc.lat, loc.lng], 17)
            marker.openPopup()
          })
        })
      })
      .catch(error => console.error('Error loading college locations:', error))
  }

  isWithinCampus(lat, lng) {
    return lat >= this.CUHK_BOUNDS.minLat &&
           lat <= this.CUHK_BOUNDS.maxLat &&
           lng >= this.CUHK_BOUNDS.minLng &&
           lng <= this.CUHK_BOUNDS.maxLng
  }

  updateFormFields(lat, lng) {
    if (this.latInputTarget) this.latInputTarget.value = lat.toFixed(6)
    if (this.lngInputTarget) this.lngInputTarget.value = lng.toFixed(6)
    
    // Find closest CUHK location
    this.findClosestLocation(lat, lng)
  }

  findClosestLocation(lat, lng) {
    fetch(`/api/locations/closest?lat=${lat}&lng=${lng}`)
      .then(response => response.json())
      .then(data => {
        if (this.locationNameInputTarget && data.key) {
          this.locationNameInputTarget.value = data.key
        }
      })
      .catch(error => console.error('Error finding location:', error))
  }
}
