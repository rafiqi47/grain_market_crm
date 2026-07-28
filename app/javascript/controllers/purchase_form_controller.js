// app/javascript/controllers/purchase_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "itemsContainer", "itemTemplate",
    "totalAmount", "amountPaid", "amountOnCredit"
  ]

  connect() {
    this.rowIndex = this.itemsContainerTarget.querySelectorAll(".purchase-row").length
    this.recalculate()
  }

  addRow(event) {
    event.preventDefault()
    const currentIndex = this.rowIndex
    const html = this.itemTemplateTarget.innerHTML.replace(/INDEX/g, currentIndex)
    this.itemsContainerTarget.insertAdjacentHTML("beforeend", html)

    const rows   = this.itemsContainerTarget.querySelectorAll(".purchase-row")
    const newRow = rows[rows.length - 1]
    const newBtn = newRow?.querySelector("[data-row-index]")
    if (newBtn) newBtn.dataset.rowIndex = currentIndex

    this.rowIndex++
    this.recalculate()
  }

  removeRow(event) {
    event.preventDefault()
    event.currentTarget.closest(".purchase-row").remove()
    this.recalculate()
  }

  productChanged(event) {
    const select = event.currentTarget
    const row    = select.closest(".purchase-row")
    const opt    = select.options[select.selectedIndex]
    const cat    = opt?.dataset?.category || ""
    const unit   = opt?.dataset?.unit     || ""

    row.querySelector(".row-category")?.setAttribute("value", cat)
    row.querySelector(".row-unit")?.setAttribute("value", unit)

    this.toggleRowFields(row, unit)
    this.recalculate()
  }

  toggleRowFields(row, unit) {
    // Hide all unit-specific field groups
    row.querySelectorAll(".count-fields").forEach(el  => el.classList.add("hidden"))
    row.querySelectorAll(".kg-fields").forEach(el     => el.classList.add("hidden"))
    row.querySelectorAll(".packet-fields").forEach(el => el.classList.add("hidden"))

    // Always show shared fields (batch, dates, line total) when a unit is set
    if (unit) {
      row.querySelectorAll(".shared-fields").forEach(el => el.classList.remove("hidden"))
    }

    // Show the correct unit-specific group
    if (unit === "kg") {
      row.querySelectorAll(".kg-fields").forEach(el => el.classList.remove("hidden"))
      // kg = commodity: batch/expiry optional
      row.querySelectorAll(".batch-required-label").forEach(el  => el.classList.add("hidden"))
      row.querySelectorAll(".expiry-required-label").forEach(el => el.classList.add("hidden"))

    } else if (unit === "ml" || unit === "gram") {
      row.querySelectorAll(".packet-fields").forEach(el => el.classList.remove("hidden"))
      // Update packet unit label (ml or g)
      row.querySelectorAll(".packet-unit-label").forEach(el => { el.textContent = unit })
      // non-commodity: batch/expiry required
      row.querySelectorAll(".batch-required-label").forEach(el  => el.classList.remove("hidden"))
      row.querySelectorAll(".expiry-required-label").forEach(el => el.classList.remove("hidden"))

    } else if (unit === "bag" || unit === "piece") {
      row.querySelectorAll(".count-fields").forEach(el => el.classList.remove("hidden"))
      // Update qty label
      row.querySelectorAll(".qty-count-label").forEach(el => {
        el.textContent = unit === "bag" ? "Qty (bags)" : "Qty (pieces)"
      })
      // non-commodity: batch/expiry required
      row.querySelectorAll(".batch-required-label").forEach(el  => el.classList.remove("hidden"))
      row.querySelectorAll(".expiry-required-label").forEach(el => el.classList.remove("hidden"))
    }
  }

  recalculate() {
    let total = 0

    this.itemsContainerTarget.querySelectorAll(".purchase-row").forEach(row => {
      const unit = row.querySelector(".row-unit")?.value || ""
      let lineTotal = 0

      if (unit === "kg") {
        const maund = parseFloat(row.querySelector(".qty-maund")?.value)   || 0
        const kg    = parseFloat(row.querySelector(".qty-kg")?.value)      || 0
        const rate  = parseFloat(row.querySelector(".price-kg")?.value)    || 0
        lineTotal   = (maund + kg / 40) * rate

      } else if (unit === "ml" || unit === "gram") {
        const packets = parseFloat(row.querySelector(".packet-count")?.value)  || 0
        const rate    = parseFloat(row.querySelector(".price-packet")?.value)  || 0
        lineTotal     = packets * rate

      } else {
        // bag / piece
        const qty  = parseFloat(row.querySelector(".qty-count")?.value)  || 0
        const rate = parseFloat(row.querySelector(".price-count")?.value) || 0
        lineTotal  = qty * rate
      }

      // line-total is now in the shared section — ONE per row, no ambiguity
      const lineTotalEl = row.querySelector(".line-total")
      if (lineTotalEl) {
        lineTotalEl.textContent = lineTotal > 0
          ? `Rs. ${lineTotal.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
          : "—"
      }

      total += lineTotal
    })

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
      this.amountOnCreditTarget.classList.toggle("text-red-600",   credit > 0)
      this.amountOnCreditTarget.classList.toggle("text-green-700", credit <= 0)
    }
  }

  // Called by product-modal-controller after quick-add product saved
  injectProduct(productId, productName, productCategory, productUnit, rowIndex) {
    const rows      = this.itemsContainerTarget.querySelectorAll(".purchase-row")
    const targetRow = rows[rowIndex]
    if (!targetRow) return

    const select = targetRow.querySelector(".product-select")
    if (!select) return

    const option             = document.createElement("option")
    option.value             = productId
    option.textContent       = productName
    option.dataset.category  = productCategory
    option.dataset.unit      = productUnit
    select.appendChild(option)
    select.value = productId

    targetRow.querySelector(".row-category")?.setAttribute("value", productCategory)
    targetRow.querySelector(".row-unit")?.setAttribute("value", productUnit)

    this.toggleRowFields(targetRow, productUnit)
    this.recalculate()
  }
}
