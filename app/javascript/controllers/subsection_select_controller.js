import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sectionSelect", "subsectionSelect"]

  connect() {
    if (this.hasSectionSelectTarget && this.sectionSelectTarget.value) {
      this.loadSubsections(this.sectionSelectTarget.value)
    }
  }

  async changeSection() {
    const sectionId = this.sectionSelectTarget.value

    this.resetSubsectionOptions()

    if (!sectionId) return

    await this.loadSubsections(sectionId)
  }

  async loadSubsections(sectionId) {
    try {
      const response = await fetch(`/admin/sidebar_subsections/by_section?sidebar_section_id=${sectionId}`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error("Erro ao carregar subseções")

      const subsections = await response.json()
      this.populateSubsections(subsections)
    } catch (error) {
      console.error("Erro ao buscar subseções:", error)
    }
  }

  resetSubsectionOptions() {
    this.subsectionSelectTarget.innerHTML = ""

    const defaultOption = document.createElement("option")
    defaultOption.value = ""
    defaultOption.textContent = "Sem subseção"
    this.subsectionSelectTarget.appendChild(defaultOption)
  }

  populateSubsections(subsections) {
    this.resetSubsectionOptions()

    subsections.forEach((subsection) => {
      const option = document.createElement("option")
      option.value = subsection.id
      option.textContent = subsection.title
      this.subsectionSelectTarget.appendChild(option)
    })
  }
}