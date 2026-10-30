import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "previews"]

  disconnect() {
    this.#revoke()
  }

  preview() {
    this.#revoke()
    this.urls = Array.from(this.inputTarget.files).map((file) => URL.createObjectURL(file))
    this.previewsTarget.replaceChildren(...this.urls.map((url) => {
      const item = document.createElement("span")
      item.className = "photo-picker__item photo-picker__item--new"
      const image = document.createElement("img")
      image.src = url
      image.alt = ""
      item.append(image)
      return item
    }))
  }

  #revoke() {
    this.urls?.forEach((url) => URL.revokeObjectURL(url))
  }
}
