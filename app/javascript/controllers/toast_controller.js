import { Controller } from "@hotwired/stimulus"
import { vibrate } from "../lib/haptics"

export default class extends Controller {
  static values = { live: Boolean }

  connect() {
    // Live notifications (new match, new message) stay a little longer and buzz.
    if (this.liveValue) vibrate([15, 40, 15])
    this.timer = setTimeout(() => this.dismiss(), this.liveValue ? 6000 : 4500)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("is-leaving")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }
}
