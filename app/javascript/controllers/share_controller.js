import { Controller } from "@hotwired/stimulus"
import { toast } from "../lib/toast"

export default class extends Controller {
  static values = { title: String, text: String, url: String }

  async share() {
    const data = { title: this.titleValue, text: this.textValue, url: this.urlValue }

    if (navigator.canShare?.(data)) {
      try {
        await navigator.share(data)
      } catch {
        // Share sheet dismissed.
      }
    } else {
      await navigator.clipboard?.writeText(this.urlValue)
      toast("Lien copié 📋")
    }
  }
}
