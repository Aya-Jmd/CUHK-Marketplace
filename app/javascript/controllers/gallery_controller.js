import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "mainImage" ]

  swap(event) {
    const newImageUrl = event.currentTarget.dataset.fullUrl

    this.mainImageTarget.src = newImageUrl
  }
}
