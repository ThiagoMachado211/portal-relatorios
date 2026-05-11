import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["children", "icon"]

  toggle() {
    this.childrenTarget.classList.toggle("hidden")

    if (this.iconTarget.textContent.trim() === "▸") {
      this.iconTarget.textContent = "▾"
    } else {
      this.iconTarget.textContent = "▸"
    }
  }
}