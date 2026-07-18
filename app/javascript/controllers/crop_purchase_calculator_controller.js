// app/javascript/controllers/crop_purchase_calculator_controller.js
import { Controller } from "@hotwired/stimulus"

const KG_PER_MAUND = 40

export default class extends Controller {
  static targets = [
    "grossMaund", "grossKg",
    "kattMaund", "kattKg",
    "marketRate", "commission", "labor",
    "netWeightOut", "grossValueOut", "netLedgerValueOut"
  ]

  connect() {
    this.calculate()
  }

  calculate() {
    const grossKgTotal = this.toNumber(this.grossMaundTarget.value) * KG_PER_MAUND + this.toNumber(this.grossKgTarget.value)
    const kattKgTotal = this.toNumber(this.kattMaundTarget.value) * KG_PER_MAUND + this.toNumber(this.kattKgTarget.value)
    const marketRate = this.toNumber(this.marketRateTarget.value)
    const commission = this.toNumber(this.commissionTarget.value)
    const labor = this.toNumber(this.laborTarget.value)

    const netWeightKg = Math.max(grossKgTotal - kattKgTotal, 0)
    const grossValue = (netWeightKg / KG_PER_MAUND) * marketRate
    const netLedgerValue = grossValue - commission - labor

    this.netWeightOutTarget.textContent = this.formatMaundKg(netWeightKg)
    this.grossValueOutTarget.textContent = this.formatCurrency(grossValue)
    this.netLedgerValueOutTarget.textContent = this.formatCurrency(netLedgerValue)
  }

  toNumber(value) {
    const parsed = parseFloat(value)
    return Number.isFinite(parsed) ? parsed : 0
  }

  formatMaundKg(kgValue) {
    const maund = Math.floor(kgValue / KG_PER_MAUND)
    const kg = (kgValue % KG_PER_MAUND).toFixed(2)
    return `${maund} Maund ${kg} KG`
  }

  formatCurrency(value) {
    return value.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
