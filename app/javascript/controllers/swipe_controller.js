import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { request } from "../lib/http"
import { vibrate } from "../lib/haptics"

const SWIPE_THRESHOLD = 110
const FLICK_VELOCITY = 0.6
const MAX_ROTATION = 14

export default class extends Controller {
  static targets = ["stack", "card", "empty", "actions", "match", "matchPhoto", "matchName", "matchOwner", "matchLink"]
  static values = { url: String }

  connect() {
    this.onKeydown = this.#keydown.bind(this)
    document.addEventListener("keydown", this.onKeydown)
    this.#layout()
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  cardTargetConnected(card) {
    card.addEventListener("pointerdown", this.#pointerDown)
  }

  cardTargetDisconnected(card) {
    card.removeEventListener("pointerdown", this.#pointerDown)
  }

  like() {
    this.#decide(this.#top, true)
  }

  pass() {
    this.#decide(this.#top, false)
  }

  open() {
    if (this.#top) Turbo.visit(this.#top.dataset.url)
  }

  closeMatch() {
    this.matchTarget.close()
  }

  get #top() {
    return this.cardTargets.find((card) => !card.dataset.decided)
  }

  #layout() {
    const cards = this.cardTargets.filter((card) => !card.dataset.decided)
    cards.forEach((card, index) => {
      card.style.zIndex = String(cards.length - index)
      card.style.setProperty("--depth", Math.min(index, 2))
      card.classList.toggle("is-top", index === 0)
    })
    this.emptyTarget.hidden = cards.length > 0
    this.actionsTarget.hidden = cards.length === 0
  }

  #pointerDown = (event) => {
    const card = event.currentTarget
    if (card !== this.#top || event.button > 0) return

    card.setPointerCapture(event.pointerId)
    card.classList.add("is-dragging")
    const start = { x: event.clientX, y: event.clientY, time: performance.now() }
    let dx = 0
    let dy = 0

    const move = (moveEvent) => {
      dx = moveEvent.clientX - start.x
      dy = moveEvent.clientY - start.y
      this.#drag(card, dx, dy)
    }

    const end = () => {
      card.removeEventListener("pointermove", move)
      card.removeEventListener("pointerup", end)
      card.removeEventListener("pointercancel", end)
      card.classList.remove("is-dragging")

      const velocity = Math.abs(dx) / (performance.now() - start.time)
      if (Math.abs(dx) > SWIPE_THRESHOLD || (velocity > FLICK_VELOCITY && Math.abs(dx) > 30)) {
        this.#decide(card, dx > 0, { dx, dy })
      } else if (Math.hypot(dx, dy) < 6) {
        this.#reset(card)
        Turbo.visit(card.dataset.url)
      } else {
        this.#reset(card)
      }
    }

    card.addEventListener("pointermove", move)
    card.addEventListener("pointerup", end)
    card.addEventListener("pointercancel", end)
  }

  #drag(card, dx, dy) {
    const rotation = Math.max(-MAX_ROTATION, Math.min(MAX_ROTATION, dx / 14))
    card.style.transform = `translate3d(${dx}px, ${dy * 0.4}px, 0) rotate(${rotation}deg)`
    card.style.setProperty("--like", Math.max(0, Math.min(1, dx / SWIPE_THRESHOLD)))
    card.style.setProperty("--nope", Math.max(0, Math.min(1, -dx / SWIPE_THRESHOLD)))
  }

  #reset(card) {
    card.style.transform = ""
    card.style.setProperty("--like", 0)
    card.style.setProperty("--nope", 0)
  }

  async #decide(card, liked, { dx = 0, dy = 0 } = {}) {
    if (!card || card.dataset.decided) return
    card.dataset.decided = "true"

    const direction = liked ? 1 : -1
    const flyX = direction * (window.innerWidth + card.offsetWidth)
    card.style.setProperty(liked ? "--like" : "--nope", 1)
    card.classList.add("is-leaving")
    card.style.transform = `translate3d(${flyX}px, ${dy * 0.4 + 40}px, 0) rotate(${direction * 24}deg)`
    card.addEventListener("transitionend", () => card.remove(), { once: true })
    setTimeout(() => card.remove(), 600)

    vibrate(liked ? 12 : 6)
    this.#layout()

    try {
      const result = await request(this.urlValue, { method: "POST", body: { dog_id: card.dataset.dogId, liked } })
      if (result?.match) this.#celebrate(card, result.chatroom_url)
    } catch {
      // The decision is simply retried next time this dog shows up in the deck.
    }
  }

  #celebrate(card, chatroomUrl) {
    this.matchPhotoTarget.src = card.dataset.photo || ""
    this.matchNameTarget.textContent = card.dataset.dogName
    this.matchOwnerTarget.textContent = card.dataset.ownerName
    this.matchLinkTarget.href = chatroomUrl
    this.matchTarget.showModal()
    vibrate([30, 60, 30, 60, 90])
  }

  #keydown(event) {
    if (this.matchTarget.open || event.target.closest("input, textarea, select")) return
    if (event.key === "ArrowRight") this.like()
    if (event.key === "ArrowLeft") this.pass()
  }
}
