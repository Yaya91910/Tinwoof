import { Controller } from "@hotwired/stimulus"
import { request } from "../lib/http"

export default class extends Controller {
  static targets = ["scroller", "messages", "form", "input"]
  static values = { readUrl: String }

  connect() {
    this.#scrollToBottom("instant")
    this.observer = new MutationObserver(() => this.#scrollToBottom("smooth"))
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
    // Messages received while the conversation was open have been seen.
    request(this.readUrlValue, { method: "PATCH", keepalive: true }).catch(() => {})
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

  #scrollToBottom(behavior) {
    this.scrollerTarget.scrollTo({ top: this.scrollerTarget.scrollHeight, behavior })
  }
}
