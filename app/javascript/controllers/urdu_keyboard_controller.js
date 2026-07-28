// app/javascript/controllers/urdu_keyboard_controller.js
import { Controller } from "@hotwired/stimulus"

const URDU_KEYS = [
  // Row 1
  ["ا", "آ", "ب", "پ", "ت", "ٹ", "ث", "ج", "چ", "ح"],
  // Row 2
  ["خ", "د", "ڈ", "ذ", "ر", "ڑ", "ز", "ژ", "س", "ش"],
  // Row 3
  ["ص", "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ک", "گ"],
  // Row 4
  ["ل", "م", "ن", "ں", "و", "ہ", "ھ", "ء", "ی", "ے"],
  // Row 5 — punctuation + space
  [" ", "!", "؟", "،", "۔"]
]

export default class extends Controller {
  static targets = ["input", "keyboard"]

  connect() {
    this.activeField = null
    this.buildKeyboard()
  }

  buildKeyboard() {
    const keyboard = this.keyboardTarget
    keyboard.innerHTML = ""
    keyboard.style.cssText = `
      display: none;
      direction: rtl;
      background: var(--surface-1);
      border: 0.5px solid var(--border);
      border-radius: 8px;
      padding: 8px;
      margin-top: 4px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    `

    URDU_KEYS.forEach(row => {
      const rowDiv = document.createElement("div")
      rowDiv.style.cssText = "display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 4px; justify-content: flex-end;"

      row.forEach(key => {
        const btn = document.createElement("button")
        btn.type = "button"
        btn.textContent = key === " " ? "space" : key
        btn.dataset.key = key
        btn.style.cssText = `
          font-family: 'Noto Nastaliq Urdu', serif;
          font-size: ${key === " " ? "12px" : "16px"};
          padding: ${key === " " ? "6px 24px" : "6px 10px"};
          border: 0.5px solid var(--border);
          border-radius: 4px;
          background: var(--surface-2);
          color: var(--text-primary);
          cursor: pointer;
          min-width: 36px;
          text-align: center;
          transition: background 0.1s;
        `

        btn.addEventListener("mouseenter", () => {
          btn.style.background = "var(--surface-0)"
        })
        btn.addEventListener("mouseleave", () => {
          btn.style.background = "var(--surface-2)"
        })
        btn.addEventListener("mousedown", (e) => {
          e.preventDefault() // prevent input from losing focus
          this.insertCharacter(key)
        })

        rowDiv.appendChild(btn)
      })

      keyboard.appendChild(rowDiv)
    })

    // Backspace button
    const backspaceRow = document.createElement("div")
    backspaceRow.style.cssText = "display: flex; justify-content: flex-start; margin-top: 4px;"
    const backspaceBtn = document.createElement("button")
    backspaceBtn.type = "button"
    backspaceBtn.textContent = "⌫ حذف"
    backspaceBtn.style.cssText = `
      font-family: 'Noto Nastaliq Urdu', serif;
      font-size: 13px;
      padding: 6px 14px;
      border: 0.5px solid var(--border);
      border-radius: 4px;
      background: var(--surface-2);
      color: var(--text-primary);
      cursor: pointer;
    `
    backspaceBtn.addEventListener("mousedown", (e) => {
      e.preventDefault()
      this.deleteCharacter()
    })
    backspaceRow.appendChild(backspaceBtn)
    keyboard.appendChild(backspaceRow)
  }

  // Called when an input field gains focus
  focusField(event) {
    this.activeField = event.target
    this.keyboardTarget.style.display = "block"
  }

  // Called when an input field loses focus
  blurField(event) {
    // Small delay so mousedown on keyboard button fires before blur hides it
    setTimeout(() => {
      this.keyboardTarget.style.display = "none"
      this.activeField = null
    }, 150)
  }

  insertCharacter(char) {
    if (!this.activeField) return

    const start = this.activeField.selectionStart
    const end = this.activeField.selectionEnd
    const value = this.activeField.value

    this.activeField.value = value.slice(0, start) + char + value.slice(end)
    this.activeField.selectionStart = this.activeField.selectionEnd = start + char.length
    this.activeField.dispatchEvent(new Event("input", { bubbles: true }))
    this.activeField.focus()
  }

  deleteCharacter() {
    if (!this.activeField) return

    const start = this.activeField.selectionStart
    const end = this.activeField.selectionEnd
    const value = this.activeField.value

    if (start === end && start > 0) {
      this.activeField.value = value.slice(0, start - 1) + value.slice(end)
      this.activeField.selectionStart = this.activeField.selectionEnd = start - 1
    } else if (start !== end) {
      this.activeField.value = value.slice(0, start) + value.slice(end)
      this.activeField.selectionStart = this.activeField.selectionEnd = start
    }

    this.activeField.dispatchEvent(new Event("input", { bubbles: true }))
    this.activeField.focus()
  }
}
