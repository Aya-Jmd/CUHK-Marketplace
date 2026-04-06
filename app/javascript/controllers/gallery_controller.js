import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // We define the main image as a target so we can easily swap its source
  static targets = [ "mainImage" ]

  swap(event) {
    // 1. Get the high-resolution URL from the clicked thumbnail
    const newImageUrl = event.currentTarget.dataset.fullUrl
    
    // 2. Change the src of the main image
    this.mainImageTarget.src = newImageUrl
  }
}