import { Controller } from "@hotwired/stimulus"
import { metaContent, request } from "../lib/http"

export default class extends Controller {
  static targets = ["scroller", "messages", "form", "input"]
  static values = { readUrl: String }

  connect() {
    this.#scrollToBottom("instant")
    this.observer = new MutationObserver((mutations) => {
      this.#scrollToBottom("smooth")
      if (this.#receivedMessage(mutations)) this.#markReadSoon()
    })
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.readTimer)
    // Messages received while the conversation was open have been seen.
    this.#markRead({ keepalive: true })
  }

  submitOnEnter(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return
    // On touch devices Enter inserts a new line; the send button submits.
    if (window.matchMedia("(pointer: coarse)").matches) return

    event.preventDefault()
    if (this.inputTarget.value.trim()) this.formTarget.requestSubmit()
  }

  resize() {
    this.inputTarget.style.height = "auto"
    this.inputTarget.style.height = `${Math.min(this.inputTarget.scrollHeight, 140)}px`
  }

  reset(event) {
    if (!event.detail.success) return
    this.formTarget.reset()
    this.resize()
    this.inputTarget.focus()
  }

  #receivedMessage(mutations) {
    const me = metaContent("current-user-id")
    return mutations.some((mutation) =>
      Array.from(mutation.addedNodes).some((node) => node.dataset?.authorId && node.dataset.authorId !== me))
  }

  // Reading live lets the sender see "Vu" right away.
  #markReadSoon() {
    if (document.visibilityState !== "visible") return
    clearTimeout(this.readTimer)
    this.readTimer = setTimeout(() => this.#markRead(), 800)
  }

  #markRead({ keepalive = false } = {}) {
    request(this.readUrlValue, { method: "PATCH", keepalive }).catch(() => {})
  }

  #scrollToBottom(behavior) {
    this.scrollerTarget.scrollTo({ top: this.scrollerTarget.scrollHeight, behavior })
  }
}
