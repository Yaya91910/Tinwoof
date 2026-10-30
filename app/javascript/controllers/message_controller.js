import { Controller } from "@hotwired/stimulus"
import { metaContent } from "../lib/http"

// Broadcast messages are rendered once for both participants:
// alignment is decided client-side by comparing the author with the current user.
export default class extends Controller {
  connect() {
    this.element.classList.toggle("message--mine", this.element.dataset.authorId === metaContent("current-user-id"))
  }
}
