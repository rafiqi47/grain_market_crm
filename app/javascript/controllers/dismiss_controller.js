import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dismiss"
export default class extends Controller {
  dismiss() {
    this.element.remove()
  }
  connect() {
    setTimeout(() => {
      this.dismiss()
    }, 5000)
  }
}
