import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list"]

  search() {
    const query = this.inputTarget.value.toLowerCase()
    const rows = this.listTarget.querySelectorAll(".organization-row")

    rows.forEach(row => {
      const name = row.dataset.searchName
      if (name.includes(query)) {
        row.style.display = ""
      } else {
        row.style.display = "none"
      }
    })
  }
}
