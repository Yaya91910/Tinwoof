import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "dots"]

  connect() {
    if (!this.hasDotsTarget) return

    this.observer = new IntersectionObserver((entries) => {
      entries.filter((entry) => entry.isIntersecting).forEach((entry) => {
        this.#activate(this.slideTargets.indexOf(entry.target))
      })
    }, { root: this.trackTarget, threshold: 0.6 })
    this.slideTargets.forEach((slide) => this.observer.observe(slide))
    this.#activate(0)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  go(event) {
    const slide = this.slideTargets[Number(event.currentTarget.dataset.index)]
    this.trackTarget.scrollTo({ left: slide.offsetLeft, behavior: "smooth" })
  }

  #activate(index) {
    Array.from(this.dotsTarget.children).forEach((dot, i) => dot.setAttribute("aria-current", String(i === index)))
  }
}
