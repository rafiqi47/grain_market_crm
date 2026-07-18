// app/javascript/controllers/crop_sale_calculator_controller.js
import { Controller } from "@hotwired/stimulus"

const KG_PER_MAUND = 40

export default class extends Controller {
  static targets = ["maund", "kg", "rate", "totalValueOut"]

  connect() {
    this.calculate()
  }

  calculate() {
    const weightKg = this.toNumber(this.maundTarget.value) * KG_PER_MAUND + this.toNumber(this.kgTarget.value)
    const rate = this.toNumber(this.rateTarget.value)

    const totalValue = (weightKg / KG_PER_MAUND) * rate

    this.totalValueOutTarget.textContent = totalValue.toLocaleString("en-PK", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    })
  }

  toNumber(value) {
    const parsed = parseFloat(value)
    return Number.isFinite(parsed) ? parsed : 0
  }
}
