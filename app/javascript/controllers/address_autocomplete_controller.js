import { Controller } from "@hotwired/stimulus"
import { currentPosition, forwardGeocode, reverseGeocode } from "../lib/geo"

// Address autocomplete (Photon / OpenStreetMap). Free text still works:
// it is geocoded server-side on save.
export default class extends Controller {
  static targets = ["input", "list", "latitude", "longitude", "locate"]
  static values = { proximity: Array }

  connect() {
    this.results = []
    this.activeIndex = -1
  }

  disconnect() {
    this.abort?.abort()
  }

  search() {
    this.#setCoordinates(null)

    clearTimeout(this.timer)
    const query = this.inputTarget.value.trim()
    if (query.length < 3) return this.close()

    this.timer = setTimeout(async () => {
      this.abort?.abort()
      this.abort = new AbortController()
      try {
        const proximity = this.proximityValue.length ? this.proximityValue : null
        this.results = await forwardGeocode(query, { proximity, signal: this.abort.signal })
        this.#renderList()
      } catch {
        // Aborted by a newer keystroke, or offline.
      }
    }, 220)
  }

  navigate(event) {
    if (this.listTarget.hidden) return

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      this.activeIndex = (this.activeIndex + step + this.results.length) % this.results.length
      this.#highlight()
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.#choose(this.results[this.activeIndex])
    } else if (event.key === "Escape") {
      this.close()
    }
  }

  close() {
    // Delay so a click on a suggestion lands before the list disappears.
    setTimeout(() => {
      this.listTarget.hidden = true
      this.inputTarget.setAttribute("aria-expanded", "false")
      this.activeIndex = -1
    }, 150)
  }

  async locate() {
    this.locateTarget.classList.add("is-loading")
    try {
      const position = await currentPosition({ enableHighAccuracy: true, maximumAge: 0 })
      const coordinates = [position.coords.longitude, position.coords.latitude]
      const label = await reverseGeocode(coordinates)
      this.inputTarget.value = label || "Ma position"
      this.#setCoordinates(coordinates)
    } catch {
      this.inputTarget.focus()
    } finally {
      this.locateTarget.classList.remove("is-loading")
    }
  }

  #renderList() {
    this.listTarget.replaceChildren(...this.results.map((result, index) => {
      const option = document.createElement("li")
      option.className = "autocomplete__option"
      option.id = `address-option-${index}`
      option.setAttribute("role", "option")
      const name = document.createElement("strong")
      name.textContent = result.name
      const context = document.createElement("span")
      context.textContent = result.context || ""
      option.append(name, context)
      option.addEventListener("mousedown", (event) => {
        event.preventDefault()
        this.#choose(result)
      })
      return option
    }))

    const open = this.results.length > 0
    this.listTarget.hidden = !open
    this.inputTarget.setAttribute("aria-expanded", String(open))
    this.activeIndex = -1
  }

  #highlight() {
    Array.from(this.listTarget.children).forEach((option, index) => {
      option.setAttribute("aria-selected", String(index === this.activeIndex))
    })
    this.inputTarget.setAttribute("aria-activedescendant", `address-option-${this.activeIndex}`)
  }

  #choose(result) {
    this.inputTarget.value = result.label
    this.#setCoordinates(result.coordinates)
    this.close()
  }

  #setCoordinates(coordinates) {
    this.longitudeTarget.value = coordinates ? coordinates[0] : ""
    this.latitudeTarget.value = coordinates ? coordinates[1] : ""
  }
}
