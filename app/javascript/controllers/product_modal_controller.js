// app/javascript/controllers/product_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "form", "errors", "submitBtn"]
  static values  = { url: String }

  connect() {
    this.currentRowIndex = null
    this.handleKeydown   = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  open(event) {
    event.preventDefault()
    this.currentRowIndex = parseInt(event.currentTarget.dataset.rowIndex)
    this.clearForm()
    this.clearErrors()
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.querySelector("input[type='text']")?.focus()
  }

  close(event) {
    event?.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.currentRowIndex = null
  }

  backdropClick(event) {
    if (event.target === this.modalTarget) this.close()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    }
  }

  async submit(event) {
    event.preventDefault()
    this.submitBtnTarget.disabled    = true
    this.submitBtnTarget.textContent = "Saving..."
    this.clearErrors()

    const formData = new FormData(this.formTarget)

    try {
      const response = await fetch(this.urlValue, {
        method:  "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
          "Accept":       "application/json"
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        const purchaseForm = document.querySelector("[data-controller~='purchase-form']")
        if (purchaseForm) {
          const controller = this.application.getControllerForElementAndIdentifier(
            purchaseForm, "purchase-form"
          )
          controller?.injectProduct(
            data.product.id,
            data.product.name,
            data.product.category,
            data.product.unit,        // ← pass unit
            this.currentRowIndex
          )
        }
        this.close()
      } else {
        this.showErrors(data.errors || ["Something went wrong."])
      }
    } catch (error) {
      this.showErrors(["Network error — please try again."])
    } finally {
      this.submitBtnTarget.disabled    = false
      this.submitBtnTarget.textContent = "Add Product"
    }
  }

  showErrors(errors) {
    this.errorsTarget.innerHTML = errors.map(e => `<li>${e}</li>`).join("")
    this.errorsTarget.closest(".error-box").classList.remove("hidden")
  }

  clearErrors() {
    this.errorsTarget.innerHTML = ""
    this.errorsTarget.closest(".error-box")?.classList.add("hidden")
  }

  clearForm() {
    this.formTarget.reset()
  }
}
