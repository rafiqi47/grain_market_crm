import { Controller } from "@hotwired/stimulus"

const COMMODITY_CATEGORIES = ["seed", "oil_cake", "wanda"]

export default class extends Controller {
  static targets = [
    "supplierSelect", "productSelect", "batchSelect",
    "productWrapper", "batchWrapper", "quantityWrapper",
    "maundKgFields", "unitsField", "maundField", "kgField", "quantityField",
    "reasonSelect", "directionWrapper", "directionLabel",
    "customerReturnWrapper", "customerTypeSelect",
    "farmerWrapper", "tradingPartnerWrapper",
    "supplierReturnWrapper"
  ]

  static values = {
    selectedSupplierId: String,
    selectedProductId:  String,
    selectedBatchId:    String,
    selectedReason:     String,
    selectedCustomerType: String
  }

  connect() {
    this.selectedBatchCategory = null

    // Re-populate cascade on failed form submission
    if (this.selectedSupplierIdValue) {
      this.repopulateCascade()
    }

    // Re-apply reason section visibility
    if (this.selectedReasonValue) {
      this.applyReasonUI(this.selectedReasonValue)
    }

    // Re-apply customer type visibility
    if (this.selectedCustomerTypeValue) {
      this.applyCustomerTypeUI(this.selectedCustomerTypeValue)
    }
  }

  async repopulateCascade() {
    const supplierId = this.selectedSupplierIdValue
    const productId  = this.selectedProductIdValue
    const batchId    = this.selectedBatchIdValue

    if (!supplierId) return

    // Load products
    try {
      const res  = await fetch(`/suppliers/${supplierId}/products_for_adjustment`)
      const data = await res.json()

      this.productSelectTarget.innerHTML = '<option value="">— Select product —</option>'
      data.products.forEach(p => {
        const opt = document.createElement("option")
        opt.value            = p.id
        opt.textContent      = p.urdu_slug ? `${p.name} / ${p.urdu_slug}` : p.name
        opt.dataset.category = p.category
        if (p.id.toString() === productId) opt.selected = true
        this.productSelectTarget.appendChild(opt)
      })
      this.productWrapperTarget.classList.remove("hidden")
    } catch(e) { return }

    if (!productId) return

    const selectedOption = this.productSelectTarget.options[this.productSelectTarget.selectedIndex]
    this.selectedBatchCategory = selectedOption?.dataset?.category || null

    // Load batches
    try {
      const res  = await fetch(`/suppliers/${supplierId}/products/${productId}/batches_for_adjustment`)
      const data = await res.json()

      this.batchSelectTarget.innerHTML = '<option value="">— Select batch —</option>'
      data.batches.forEach(b => {
        const opt = document.createElement("option")
        opt.value       = b.id
        opt.textContent = b.label
        if (b.id.toString() === batchId) opt.selected = true
        this.batchSelectTarget.appendChild(opt)
      })
      this.batchWrapperTarget.classList.remove("hidden")
    } catch(e) { return }

    if (!batchId) return

    this.quantityWrapperTarget.classList.remove("hidden")
    this.toggleQuantityFields()
  }

  async supplierChanged() {
    const supplierId = this.supplierSelectTarget.value
    this.resetProduct()
    this.resetBatch()
    if (!supplierId) return

    try {
      const res  = await fetch(`/suppliers/${supplierId}/products_for_adjustment`)
      const data = await res.json()

      this.productSelectTarget.innerHTML = '<option value="">— Select product —</option>'
      data.products.forEach(p => {
        const opt = document.createElement("option")
        opt.value            = p.id
        opt.textContent      = p.urdu_slug ? `${p.name} / ${p.urdu_slug}` : p.name
        opt.dataset.category = p.category
        this.productSelectTarget.appendChild(opt)
      })
      this.productWrapperTarget.classList.remove("hidden")
    } catch(e) {
      console.error("Failed to load products", e)
    }
  }

  async productChanged() {
    const productId = this.productSelectTarget.value
    this.resetBatch()
    if (!productId) return

    const selectedOption = this.productSelectTarget.options[this.productSelectTarget.selectedIndex]
    this.selectedBatchCategory = selectedOption?.dataset?.category || null

    const supplierId = this.supplierSelectTarget.value

    try {
      const res  = await fetch(`/suppliers/${supplierId}/products/${productId}/batches_for_adjustment`)
      const data = await res.json()

      this.batchSelectTarget.innerHTML = '<option value="">— Select batch —</option>'
      data.batches.forEach(b => {
        const opt = document.createElement("option")
        opt.value       = b.id
        opt.textContent = b.label
        this.batchSelectTarget.appendChild(opt)
      })
      this.batchWrapperTarget.classList.remove("hidden")
    } catch(e) {
      console.error("Failed to load batches", e)
    }
  }

  batchChanged() {
    if (!this.batchSelectTarget.value) {
      this.quantityWrapperTarget.classList.add("hidden")
      return
    }
    this.quantityWrapperTarget.classList.remove("hidden")
    this.toggleQuantityFields()
  }

  reasonChanged() {
    const reason = this.reasonSelectTarget.value
    this.applyReasonUI(reason)
  }

  applyReasonUI(reason) {
    this.customerReturnWrapperTarget.classList.add("hidden")
    this.supplierReturnWrapperTarget.classList.add("hidden")
    this.directionWrapperTarget.classList.add("hidden")

    if (reason === "customer_return")   this.customerReturnWrapperTarget.classList.remove("hidden")
    if (reason === "supplier_return")   this.supplierReturnWrapperTarget.classList.remove("hidden")
    if (reason === "audit_correction")  this.directionWrapperTarget.classList.remove("hidden")

    const labels = {
      customer_return:     "Quantity returned (added back to inventory)",
      damaged_goods:       "Quantity damaged (deducted from inventory)",
      spillage_or_leakage: "Quantity lost (deducted from inventory)",
      supplier_return:     "Quantity to return (deducted from inventory)",
      audit_correction:    "Quantity to adjust"
    }
    if (this.hasDirectionLabelTarget) {
      this.directionLabelTarget.textContent = labels[reason] || "Quantity"
    }
  }

  customerTypeChanged() {
    this.applyCustomerTypeUI(this.customerTypeSelectTarget.value)
  }

  applyCustomerTypeUI(type) {
    this.farmerWrapperTarget.classList.add("hidden")
    this.tradingPartnerWrapperTarget.classList.add("hidden")
    if (type === "farmer")          this.farmerWrapperTarget.classList.remove("hidden")
    if (type === "trading_partner") this.tradingPartnerWrapperTarget.classList.remove("hidden")
  }

  toggleQuantityFields() {
    const isCommodity = COMMODITY_CATEGORIES.includes(this.selectedBatchCategory)
    this.maundKgFieldsTarget.classList.toggle("hidden", !isCommodity)
    this.unitsFieldTarget.classList.toggle("hidden", isCommodity)
  }

  resetProduct() {
    this.productSelectTarget.innerHTML = '<option value="">— Select product —</option>'
    this.productWrapperTarget.classList.add("hidden")
  }

  resetBatch() {
    this.batchSelectTarget.innerHTML = '<option value="">— Select batch —</option>'
    this.batchWrapperTarget.classList.add("hidden")
    this.quantityWrapperTarget.classList.add("hidden")
    this.selectedBatchCategory = null
  }
}
