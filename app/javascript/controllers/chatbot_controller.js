import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "panel",
    "backdrop",
    "messages",
    "form",
    "input",
    "submit"
  ]

  connect() {
    this.opened = false
  }

  open() {
    this.opened = true

    this.panelTarget.classList.add("chatbot-panel--open")
    this.backdropTarget.classList.add("chatbot-backdrop--visible")

    this.panelTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("chatbot-open")

    window.setTimeout(() => {
      this.inputTarget.focus()
    }, 150)
  }

  close() {
    this.opened = false

    this.panelTarget.classList.remove("chatbot-panel--open")
    this.backdropTarget.classList.remove("chatbot-backdrop--visible")

    this.panelTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("chatbot-open")
  }

  closeOnEscape(event) {
    if (event.key === "Escape" && this.opened) {
      this.close()
    }
  }

  async submit(event) {
    event.preventDefault()

    const question = this.inputTarget.value.trim()

    if (!question) {
      return
    }

    this.addMessage("user", question)

    this.inputTarget.value = ""
    this.setLoading(true)

    try {
      const response = await fetch(this.formTarget.action, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          question: question
        })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(
          data.error || "Não foi possível processar a pergunta."
        )
      }

      this.addMessage("assistant", data.answer)
    } catch (error) {
      this.addMessage(
        "error",
        error.message || "Ocorreu um erro inesperado."
      )
    } finally {
      this.setLoading(false)
      this.inputTarget.focus()
    }
  }

  addMessage(type, text) {
    const wrapper = document.createElement("div")

    wrapper.classList.add(
      "chatbot-message",
      `chatbot-message--${type}`
    )

    const content = document.createElement("div")
    content.classList.add("chatbot-message__content")

    // textContent é proposital:
    // respostas da IA não são injetadas como HTML.
    content.textContent = text

    wrapper.appendChild(content)
    this.messagesTarget.appendChild(wrapper)

    this.messagesTarget.scrollTop =
      this.messagesTarget.scrollHeight
  }

  setLoading(loading) {
    this.submitTarget.disabled = loading
    this.inputTarget.disabled = loading

    this.submitTarget.textContent =
      loading ? "Enviando..." : "Enviar"
  }

  csrfToken() {
    return document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content")
  }
}