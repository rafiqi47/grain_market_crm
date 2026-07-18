// app/javascript/controllers/customer_type_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "farmerSection", "tradingPartnerSection", "customerNameSection"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.typeSelectTarget.value

    this.farmerSectionTarget.classList.add("hidden")
    this.tradingPartnerSectionTarget.classList.add("hidden")
    this.customerNameSectionTarget.classList.remove("hidden")

    if (type === "farmer_customer") {
      this.farmerSectionTarget.classList.remove("hidden")
      this.customerNameSectionTarget.classList.add("hidden")
    } else if (type === "trading_partner_customer") {
      this.tradingPartnerSectionTarget.classList.remove("hidden")
      this.customerNameSectionTarget.classList.add("hidden")
    }
  }
}
