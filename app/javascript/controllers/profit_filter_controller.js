// app/javascript/controllers/profit_filter_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["periodSelect", "customFields", "startInput", "endInput", "form"]

  connect() {
    this.toggleCustomInputs()
  }

  changePeriod() {
    this.toggleCustomInputs()
    
    // Auto-submit immediately if the trader selects a standard range macro preset
    if (this.periodSelectTarget.value !== "custom") {
      this.submitForm()
    }
  }

  changeCustomDate() {
    // Only execute structural queries once both calendar elements contain choices
    if (this.startInputTarget.value && this.endInputTarget.value) {
      this.submitForm()
    }
  }

  toggleCustomInputs() {
    if (this.periodSelectTarget.value === "custom") {
      this.customFieldsTarget.classList.remove("hidden")
    } else {
      this.customFieldsTarget.classList.add("hidden")
    }
  }

  submitForm() {
    this.formTarget.requestSubmit()
  }
}
