import { Controller } from "@hotwired/stimulus"
import { isIos, isStandalone } from "../lib/pwa"

export default class extends Controller {
  static targets = ["button", "hint"]

  connect() {
    this.onInstallable = () => this.#render()
    document.addEventListener("pwa:installable", this.onInstallable)
    document.addEventListener("pwa:installed", this.onInstallable)
    this.#render()
  }

  disconnect() {
    document.removeEventListener("pwa:installable", this.onInstallable)
    document.removeEventListener("pwa:installed", this.onInstallable)
  }

  async install() {
    const prompt = window.tinwoofInstallPrompt
    if (!prompt) return

    prompt.prompt()
    await prompt.userChoice
    window.tinwoofInstallPrompt = null
    this.#render()
  }

  #render() {
    if (isStandalone()) {
      this.element.hidden = true
    } else if (window.tinwoofInstallPrompt) {
      this.element.hidden = false
      this.buttonTarget.hidden = false
    } else if (isIos()) {
      this.element.hidden = false
      this.buttonTarget.hidden = true
      this.hintTarget.textContent = "Sur iPhone : touchez Partager, puis « Sur l'écran d'accueil »."
    } else {
      this.element.hidden = true
    }
  }
}
