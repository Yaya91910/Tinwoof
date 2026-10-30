import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { currentPosition, distanceInMeters, geolocationPermission, reverseGeocode } from "../lib/geo"
import { request } from "../lib/http"

const MIN_MOVE_METERS = 250
const REFRESH_PAGE_METERS = 1500
const CHECK_INTERVAL_MS = 2 * 60 * 1000
const LAST_CHECK_KEY = "tinwoof:geolocation-checked-at"

// Lives on <body> for signed-in users: keeps the user's (approximate) position fresh,
// and drives the location prompts rendered by pages that depend on it.
export default class extends Controller {
  static targets = ["prompt", "denied", "button"]
  static values = { url: String, located: Boolean, latitude: Number, longitude: Number }

  async connect() {
    if (!("geolocation" in navigator)) return

    this.permission = await geolocationPermission()
    if (this.permission) this.permission.onchange = () => this.#sync()
    this.#sync()
  }

  disconnect() {
    if (this.permission) this.permission.onchange = null
  }

  async request() {
    this.buttonTargets.forEach((button) => (button.disabled = true))
    try {
      const position = await currentPosition({ enableHighAccuracy: true, maximumAge: 0 })
      await this.#save(position, { force: true })
    } catch (error) {
      if (error.code === error.PERMISSION_DENIED) this.#render("denied")
    } finally {
      this.buttonTargets.forEach((button) => (button.disabled = false))
    }
  }

  #sync() {
    const state = this.permission?.state
    if (state === "granted") {
      this.#render("granted")
      this.#refreshSilently()
    } else if (state === "denied") {
      this.#render("denied")
    } else {
      // "prompt", or unknown on browsers without the Permissions API.
      this.#render(this.locatedValue ? "granted" : "prompt")
    }
  }

  #render(state) {
    this.promptTargets.forEach((element) => (element.hidden = state !== "prompt"))
    this.deniedTargets.forEach((element) => (element.hidden = state !== "denied" || this.locatedValue))
  }

  async #refreshSilently() {
    const lastCheck = Number(sessionStorage.getItem(LAST_CHECK_KEY) || 0)
    if (this.locatedValue && Date.now() - lastCheck < CHECK_INTERVAL_MS) return
    sessionStorage.setItem(LAST_CHECK_KEY, String(Date.now()))

    try {
      await this.#save(await currentPosition())
    } catch {
      // Position unavailable (timeout, indoor…): keep the last known one.
    }
  }

  async #save(position, { force = false } = {}) {
    const coordinates = [position.coords.longitude, position.coords.latitude]
    const previous = this.locatedValue ? [this.longitudeValue, this.latitudeValue] : null
    const moved = previous ? distanceInMeters(previous, coordinates) : Infinity
    if (!force && moved < MIN_MOVE_METERS) return

    const label = await reverseGeocode(coordinates)
    await request(this.urlValue, {
      method: "PATCH",
      body: { location: { longitude: coordinates[0], latitude: coordinates[1], label } }
    })

    this.locatedValue = true
    this.longitudeValue = coordinates[0]
    this.latitudeValue = coordinates[1]
    this.dispatch("changed", { detail: { coordinates } })

    // Distances on screen are now stale: re-render the page in place.
    if (force || moved > REFRESH_PAGE_METERS) Turbo.visit(window.location.href, { action: "replace" })
  }
}
