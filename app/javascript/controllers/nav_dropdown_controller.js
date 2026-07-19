// app/javascript/controllers/nav_dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown", "chevron"]

  connect() {
    this.openGroup = null
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.handleOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  toggle(event) {
    const btn = event.currentTarget
    const groupId = btn.dataset.group
    const dropdown = this.element.querySelector(`[data-dropdown="${groupId}"]`)
    const chevron = this.element.querySelector(`[data-chevron="${groupId}"]`)

    if (this.openGroup && this.openGroup !== groupId) {
      this.closeGroup(this.openGroup)
    }

    const isOpen = dropdown.classList.contains("open")

    if (isOpen) {
      this.closeGroup(groupId)
    } else {
      dropdown.classList.add("open")
      chevron?.classList.add("open")
      btn.classList.add("nav-active")
      this.openGroup = groupId
    }
  }

  closeGroup(groupId) {
    const dropdown = this.element.querySelector(`[data-dropdown="${groupId}"]`)
    const chevron = this.element.querySelector(`[data-chevron="${groupId}"]`)
    const btn = this.element.querySelector(`[data-group="${groupId}"]`)

    dropdown?.classList.remove("open")
    chevron?.classList.remove("open")

    // Only remove active state if no child link is currently active
    if (btn && !btn.dataset.childActive) {
      btn.classList.remove("nav-active")
    }

    this.openGroup = null
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && this.openGroup) {
      this.closeGroup(this.openGroup)
    }
  }
}
