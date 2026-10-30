import { Controller } from "@hotwired/stimulus"

// Mirrors the unread count on the installed app icon (Badging API).
export default class extends Controller {
  static values = { count: Number }

  countValueChanged(count) {
    if (!("setAppBadge" in navigator)) return
    const update = count > 0 ? navigator.setAppBadge(count) : navigator.clearAppBadge()
    update.catch(() => {})
  }
}
