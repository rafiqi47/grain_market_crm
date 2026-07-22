// app/javascript/controllers/purchase_form_controller.js
import { Controller } from "@hotwired/stimulus"

const COMMODITY_CATEGORIES = ["seed", "oil_cake", "wanda"]

export default class extends Controller {
  static targets = [
    "itemsContainer",
    "itemTemplate",
    "totalAmount",
    "amountPaid",
    "amountOnCredit",
    "submitBtn"
  ]

  connect() {
    this.rowIndex = this.itemsContainerTarget.querySelectorAll(".purchase-row").length
    this.recalculate()
  }

  // Add a new line item row
  addRow(event) {
    event.preventDefault()
    const currentIndex = this.rowIndex
    const template = this.itemTemplateTarget.innerHTML.replace(/INDEX/g, currentIndex)
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", template)

    // Update the + New button's row index to match this row's actual index
    const rows = this.itemsContainerTarget.querySelectorAll(".purchase-row")
    const newRow = rows[rows.length - 1]
    const newBtn = newRow?.querySelector("[data-row-index]")
    if (newBtn) newBtn.dataset.rowIndex = currentIndex

    this.rowIndex++
    this.recalculate()
  }

  // Remove a line item row
  removeRow(event) {
    event.preventDefault()
    const row = event.currentTarget.closest(".purchase-row")
    row.remove()
    this.recalculate()
  }

  // Called when product dropdown changes — show/hide fields based on category
  productChanged(event) {
    const select = event.currentTarget
    const row = select.closest(".purchase-row")
    const selectedOption = select.options[select.selectedIndex]
    const category = selectedOption?.dataset?.category || ""

    this.toggleRowFields(row, category)

    // Store category on hidden field for controller to read
    const categoryField = row.querySelector(".row-category")
    if (categoryField) categoryField.value = category

    this.recalculate()
  }

  // Called when any quantity/price field changes
  recalculate() {
    let total = 0

    this.itemsContainerTarget.querySelectorAll(".purchase-row").forEach(row => {
      const category = row.querySelector(".row-category")?.value || ""
      const isCommodity = COMMODITY_CATEGORIES.includes(category)
      let lineTotal = 0

      if (isCommodity) {
        const maund = parseFloat(row.querySelector(".qty-maund")?.value) || 0
        const kg    = parseFloat(row.querySelector(".qty-kg")?.value) || 0
        const rate  = parseFloat(row.querySelector(".price-field")?.value) || 0
        const totalMaund = maund + (kg / 40)
        lineTotal = totalMaund * rate
      } else {
        const qty  = parseFloat(row.querySelector(".qty-field")?.value) || 0
        const rate = parseFloat(row.querySelector(".price-field")?.value) || 0
        lineTotal  = qty * rate
      }

      // Update line total display
      const lineTotalEl = row.querySelector(".line-total")
      if (lineTotalEl) {
        lineTotalEl.textContent = lineTotal > 0
          ? `Rs. ${lineTotal.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
          : "—"
      }

      total += lineTotal
    })

    // Update totals
    if (this.hasTotalAmountTarget) {
      this.totalAmountTarget.textContent = `Rs. ${total.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    }

    this.updateCredit()
  }

  updateCredit() {
    const totalText = this.totalAmountTarget?.textContent?.replace(/[^0-9.]/g, "") || "0"
    const total     = parseFloat(totalText) || 0
    const paid      = parseFloat(this.amountPaidTarget?.value) || 0
    const credit    = total - paid

    if (this.hasAmountOnCreditTarget) {
      this.amountOnCreditTarget.textContent = `Rs. ${Math.max(credit, 0).toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
      this.amountOnCreditTarget.classList.toggle("text-red-600", credit > 0)
      this.amountOnCreditTarget.classList.toggle("text-green-700", credit <= 0)
    }
  }

  // Inject a newly created product into a specific row's dropdown
  injectProduct(productId, productName, productCategory, rowIndex) {
    const rows = this.itemsContainerTarget.querySelectorAll(".purchase-row")
    const targetRow = rows[rowIndex]
    if (!targetRow) return

    const select = targetRow.querySelector(".product-select")
    if (!select) return

    // Add new option
    const option = document.createElement("option")
    option.value = productId
    option.textContent = productName
    option.dataset.category = productCategory
    select.appendChild(option)

    // Auto-select it
    select.value = productId

    // Trigger category toggle
    const categoryField = targetRow.querySelector(".row-category")
    if (categoryField) categoryField.value = productCategory
    this.toggleRowFields(targetRow, productCategory)
    this.recalculate()
  }

  toggleRowFields(row, category) {
    const isCommodity = COMMODITY_CATEGORIES.includes(category)

    // Commodity fields (Maund + KG)
    row.querySelectorAll(".commodity-fields").forEach(el => {
      el.classList.toggle("hidden", !isCommodity)
    })

    // Non-commodity fields (quantity, batch, expiry, manufacture)
    row.querySelectorAll(".non-commodity-fields").forEach(el => {
      el.classList.toggle("hidden", isCommodity)
    })

    // Price label
    const priceLabel = row.querySelector(".price-label")
    if (priceLabel) {
      priceLabel.textContent = isCommodity ? "Price / Maund" : "Price / Unit"
    }
  }
}
