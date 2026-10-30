import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timer = setTimeout(() => this.dismiss(), 4500)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.classList.add("is-leaving")
    this.element.addEventListener("animationend", () => this.element.remove(), { once: true })
  }
}
