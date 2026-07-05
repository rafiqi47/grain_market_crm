import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loader"]

  connect() {
    // Hide loader when the page finishes loading
    this.hide()
  }

  show() {
    this.loaderTarget.classList.remove("hidden")
  }

  hide() {
    this.loaderTarget.classList.add("hidden")
  }
}
