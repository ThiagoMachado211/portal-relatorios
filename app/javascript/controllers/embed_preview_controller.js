import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "frame", "image", "link", "empty", "type"]

  connect() {
    this.update()
  }

  update() {
    const url = this.inputTarget.value.trim()
    const type = this.typeTarget.value

    this.hideAll()

    if (!url) {
      this.emptyTarget.classList.remove("hidden")
      return
    }

    if (["pdf", "report", "heatmap", "streamlit"].includes(type)) {
      this.frameTarget.src = url
      this.frameTarget.classList.remove("hidden")
      return
    }

    if (type === "image") {
      this.imageTarget.src = url
      this.imageTarget.classList.remove("hidden")
      return
    }

    if (type === "external_link") {
      this.linkTarget.href = url
      this.linkTarget.textContent = url
      this.linkTarget.classList.remove("hidden")
      return
    }

    this.emptyTarget.classList.remove("hidden")
  }

  hideAll() {
    this.frameTarget.classList.add("hidden")
    this.imageTarget.classList.add("hidden")
    this.linkTarget.classList.add("hidden")
    this.emptyTarget.classList.add("hidden")
  }
}