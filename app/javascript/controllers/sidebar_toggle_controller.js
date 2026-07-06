import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "textOnly", "icon"]

  connect() {
    if (localStorage.getItem("sidebar-collapsed") === "true") {
      this.collapse()
    }
  }

  toggle() {
    if (this.containerTarget.classList.contains("md:w-64")) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  collapse() {
    this.containerTarget.classList.remove("md:w-64")
    this.containerTarget.classList.add("md:w-20", "items-center")

    // Rotate the arrow icon 180 degrees to face outward
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-180")
    }

    this.textOnlyTargets.forEach(el => el.classList.add("hidden"))
    localStorage.setItem("sidebar-collapsed", "true")
  }

  expand() {
    this.containerTarget.classList.remove("md:w-20", "items-center")
    this.containerTarget.classList.add("md:w-64")

    // Reset arrow orientation back inward
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180")
    }

    this.textOnlyTargets.forEach(el => el.classList.remove("hidden"))
    localStorage.setItem("sidebar-collapsed", "false")
  }
}
