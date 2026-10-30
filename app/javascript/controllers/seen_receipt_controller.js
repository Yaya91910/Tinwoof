import { Controller } from "@hotwired/stimulus"
import { metaContent } from "../lib/http"

// Shows "Vu" under the current user's last message once the other participant has read it.
// The element is broadcast to both participants, so visibility is decided here.
export default class extends Controller {
  static values = { readerId: String, seenAt: String }

  connect() {
    this.messages = document.getElementById("messages")
    this.observer = new MutationObserver(() => this.#render())
    if (this.messages) this.observer.observe(this.messages, { childList: true })
    this.#render()
  }

  disconnect() {
    this.observer.disconnect()
  }

  #render() {
    const me = metaContent("current-user-id")
    const last = this.messages?.lastElementChild
    const seenAt = Date.parse(this.seenAtValue)
    const sentAt = Date.parse(last?.querySelector("time")?.getAttribute("datetime"))

    this.element.hidden = !(
      this.readerIdValue !== me && last?.dataset.authorId === me && seenAt && sentAt && sentAt <= seenAt + 1000
    )
  }
}
