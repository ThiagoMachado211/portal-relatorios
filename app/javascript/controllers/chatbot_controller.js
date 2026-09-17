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
    this.loading = false
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

  inputKeydown(event) {
    if (event.key !== "Enter") {
      return
    }

    if (event.shiftKey) {
      return
    }

    event.preventDefault()

    if (!this.loading) {
      this.formTarget.requestSubmit()
    }
  }

  async submit(event) {
    event.preventDefault()

    if (this.loading) {
      return
    }

    const question =
      this.inputTarget.value.trim()

    if (!question) {
      return
    }

    this.addMessage(
      "user",
      question
    )

    this.inputTarget.value = ""

    this.setLoading(true)

    const thinkingMessage =
      this.addThinkingMessage()

    try {
      const response =
        await fetch(
          this.formTarget.action,
          {
            method: "POST",

            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "X-CSRF-Token": this.csrfToken()
            },

            body: JSON.stringify({
              question: question
            })
          }
        )

      const data =
        await response.json()

      thinkingMessage.remove()

      if (!response.ok) {
        throw new Error(
          data.error ||
          "Não foi possível processar a pergunta."
        )
      }

      this.addMessage(
        "assistant",
        data.answer
      )

    } catch (error) {
      thinkingMessage.remove()

      this.addMessage(
        "error",
        error.message ||
        "Ocorreu um erro inesperado."
      )

    } finally {
      this.setLoading(false)
      this.inputTarget.focus()
    }
  }

  async reset(event) {
    if (this.loading) {
      return
    }

    const button =
      event.currentTarget

    const url =
      button.dataset.resetUrl

    if (!url) {
      return
    }

    button.disabled = true

    try {
      const response =
        await fetch(
          url,
          {
            method: "DELETE",

            headers: {
              "Accept": "application/json",
              "X-CSRF-Token": this.csrfToken()
            }
          }
        )

      const data =
        await response.json()

      if (!response.ok) {
        throw new Error(
          data.error ||
          "Não foi possível iniciar uma nova conversa."
        )
      }

      this.clearMessages()

    } catch (error) {
      this.addMessage(
        "error",
        error.message ||
        "Não foi possível iniciar uma nova conversa."
      )

    } finally {
      button.disabled = false
      this.inputTarget.focus()
    }
  }

  clearMessages() {
    this.messagesTarget.replaceChildren()

    this.addMessage(
      "assistant",
      "Nova conversa iniciada. Como posso ajudar?"
    )
  }

  addMessage(type, text) {
    const wrapper =
      document.createElement("div")

    wrapper.classList.add(
      "chatbot-message",
      `chatbot-message--${type}`
    )

    const content =
      document.createElement("div")

    content.classList.add(
      "chatbot-message__content"
    )

    if (type === "assistant") {
      this.renderSafeMarkdown(
        content,
        text
      )
    } else {
      content.textContent = text
    }

    wrapper.appendChild(content)

    this.messagesTarget.appendChild(
      wrapper
    )

    this.scrollToBottom()

    return wrapper
  }

  addThinkingMessage() {
    const wrapper =
      document.createElement("div")

    wrapper.classList.add(
      "chatbot-message",
      "chatbot-message--assistant",
      "chatbot-message--thinking"
    )

    const content =
      document.createElement("div")

    content.classList.add(
      "chatbot-message__content"
    )

    const label =
      document.createElement("span")

    label.classList.add(
      "chatbot-thinking__label"
    )

    label.textContent = "Analisando"

    const dots =
      document.createElement("span")

    dots.classList.add(
      "chatbot-thinking__dots"
    )

    for (let index = 0; index < 3; index += 1) {
      const dot =
        document.createElement("span")

      dot.classList.add(
        "chatbot-thinking__dot"
      )

      dots.appendChild(dot)
    }

    content.appendChild(label)
    content.appendChild(dots)

    wrapper.appendChild(content)

    this.messagesTarget.appendChild(
      wrapper
    )

    this.scrollToBottom()

    return wrapper
  }

  renderSafeMarkdown(container, text) {
    const lines =
      String(text || "")
        .replace(/\r\n/g, "\n")
        .split("\n")

    let list = null

    lines.forEach((line) => {
      const trimmed =
        line.trim()

      if (!trimmed) {
        list = null

        const spacer =
          document.createElement("div")

        spacer.classList.add(
          "chatbot-markdown-spacer"
        )

        container.appendChild(spacer)

        return
      }

      const unorderedMatch =
        trimmed.match(/^[-*]\s+(.+)$/)

      const orderedMatch =
        trimmed.match(/^\d+\.\s+(.+)$/)

      if (unorderedMatch) {
        if (
          !list ||
          list.tagName !== "UL"
        ) {
          list =
            document.createElement("ul")

          list.classList.add(
            "chatbot-markdown-list"
          )

          container.appendChild(list)
        }

        const item =
          document.createElement("li")

        this.appendInlineMarkdown(
          item,
          unorderedMatch[1]
        )

        list.appendChild(item)

        return
      }

      if (orderedMatch) {
        if (
          !list ||
          list.tagName !== "OL"
        ) {
          list =
            document.createElement("ol")

          list.classList.add(
            "chatbot-markdown-list"
          )

          container.appendChild(list)
        }

        const item =
          document.createElement("li")

        this.appendInlineMarkdown(
          item,
          orderedMatch[1]
        )

        list.appendChild(item)

        return
      }

      list = null

      const paragraph =
        document.createElement("div")

      paragraph.classList.add(
        "chatbot-markdown-line"
      )

      this.appendInlineMarkdown(
        paragraph,
        line
      )

      container.appendChild(
        paragraph
      )
    })
  }

  appendInlineMarkdown(container, text) {
    const source =
      String(text || "")

    const pattern =
      /(\*\*[^*]+\*\*)/g

    const parts =
      source.split(pattern)

    parts.forEach((part) => {
      if (
        part.startsWith("**") &&
        part.endsWith("**") &&
        part.length > 4
      ) {
        const strong =
          document.createElement("strong")

        strong.textContent =
          part.slice(2, -2)

        container.appendChild(
          strong
        )
      } else {
        container.appendChild(
          document.createTextNode(part)
        )
      }
    })
  }

  setLoading(loading) {
    this.loading = loading

    this.submitTarget.disabled =
      loading

    this.submitTarget.textContent =
      loading ? "Aguarde..." : "Enviar"

    this.inputTarget.setAttribute(
      "aria-busy",
      loading ? "true" : "false"
    )
  }

  scrollToBottom() {
    window.requestAnimationFrame(() => {
      this.messagesTarget.scrollTop =
        this.messagesTarget.scrollHeight
    })
  }

  csrfToken() {
    return document
      .querySelector(
        'meta[name="csrf-token"]'
      )
      ?.getAttribute("content")
  }
}