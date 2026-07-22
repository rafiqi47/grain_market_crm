// app/javascript/controllers/supplier_tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  show(event) {
    const selectedTab = event.currentTarget.dataset.tab

    // Update tab styles
    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tab === selectedTab
      tab.classList.toggle("border-gray-900", isActive)
      tab.classList.toggle("text-gray-900", isActive)
      tab.classList.toggle("border-transparent", !isActive)
      tab.classList.toggle("text-gray-500", !isActive)
    })

    // Show/hide panels
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.panel !== selectedTab)
    })
  }
}
