import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { request } from "../lib/http"
import { vibrate } from "../lib/haptics"

const SWIPE_THRESHOLD = 110
const SUPER_THRESHOLD = 120
const FLICK_VELOCITY = 0.6
const MAX_ROTATION = 14
const TAP_DISTANCE = 6

export default class extends Controller {
  static targets = [
    "stack", "card", "empty", "actions", "undo", "superButton", "superCount",
    "match", "matchPhoto", "matchName", "matchOwner", "matchLink"
  ]
  static values = { url: String, undoUrl: String, superlikes: Number }

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

  superlikesValueChanged(count) {
    if (this.hasSuperCountTarget) this.superCountTarget.textContent = count
    if (this.hasSuperButtonTarget) {
      this.superButtonTarget.disabled = count <= 0
      this.superButtonTarget.title = count > 0 ? `${count} Super Like restant(s) aujourd'hui` : "Plus de Super Like aujourd'hui, revenez demain"
    }
  }

  like() {
    this.#decide(this.#top, { liked: true })
  }

  pass() {
    this.#decide(this.#top, { liked: false })
  }

  superlike() {
    if (this.superlikesValue <= 0) return this.#shake(this.superButtonTarget)
    this.#decide(this.#top, { liked: true, superlike: true })
  }

  open() {
    if (this.#top) Turbo.visit(this.#top.dataset.url)
  }

  async undo() {
    const last = this.lastDecision
    if (!last) return

    this.lastDecision = null
    this.undoTarget.disabled = true
    try {
      const result = await request(this.undoUrlValue, { method: "DELETE" })
      this.superlikesValue = result.superlikes_left
      this.#restore(last.card)
      vibrate(8)
    } catch {
      this.#shake(this.undoTarget)
    }
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
    this.actionsTarget.hidden = cards.length === 0 && !this.lastDecision
  }

  #pointerDown = (event) => {
    const card = event.currentTarget
    if (card !== this.#top || event.button > 0 || event.target.closest("button, a")) return

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
      if (-dy > SUPER_THRESHOLD && Math.abs(dy) > Math.abs(dx)) {
        this.#reset(card)
        this.superlike()
      } else if (Math.abs(dx) > SWIPE_THRESHOLD || (velocity > FLICK_VELOCITY && Math.abs(dx) > 30)) {
        this.#decide(card, { liked: dx > 0, dx, dy })
      } else {
        this.#reset(card)
        if (Math.hypot(dx, dy) < TAP_DISTANCE) this.#tap(card, start.x)
      }
    }

    card.addEventListener("pointermove", move)
    card.addEventListener("pointerup", end)
    card.addEventListener("pointercancel", end)
  }

  #drag(card, dx, dy) {
    const rotation = Math.max(-MAX_ROTATION, Math.min(MAX_ROTATION, dx / 14))
    const upward = Math.max(0, -dy) > Math.abs(dx)
    card.style.transform = `translate3d(${dx}px, ${dy * (upward ? 0.8 : 0.4)}px, 0) rotate(${upward ? 0 : rotation}deg)`
    card.style.setProperty("--like", upward ? 0 : Math.max(0, Math.min(1, dx / SWIPE_THRESHOLD)))
    card.style.setProperty("--nope", upward ? 0 : Math.max(0, Math.min(1, -dx / SWIPE_THRESHOLD)))
    card.style.setProperty("--super", upward ? Math.min(1, -dy / SUPER_THRESHOLD) : 0)
  }

  #reset(card) {
    card.style.transform = ""
    for (const name of ["--like", "--nope", "--super"]) card.style.setProperty(name, 0)
  }

  // Tapping the left or right side of a card browses its photos, like a story.
  #tap(card, clientX) {
    const photos = JSON.parse(card.dataset.photos || "[]")
    if (photos.length < 2) return this.open()

    const rect = card.getBoundingClientRect()
    const current = Number(card.dataset.photoIndex || 0)
    const step = clientX - rect.left < rect.width * 0.4 ? -1 : 1
    const next = current + step
    if (next < 0 || next >= photos.length) return this.#nudge(card, step)

    card.dataset.photoIndex = next
    card.querySelector(".swipe-card__photo").src = photos[next]
    card.querySelectorAll(".swipe-card__progress span").forEach((bar, index) => bar.classList.toggle("is-active", index === next))
    vibrate(4)
  }

  async #decide(card, { liked, superlike = false, dx = 0, dy = 0 }) {
    if (!card || card.dataset.decided) return
    card.dataset.decided = "true"

    const stamp = superlike ? "--super" : (liked ? "--like" : "--nope")
    card.style.setProperty(stamp, 1)
    card.classList.add("is-leaving")
    card.style.transform = superlike
      ? `translate3d(0, ${-window.innerHeight}px, 0)`
      : `translate3d(${(liked ? 1 : -1) * (window.innerWidth + card.offsetWidth)}px, ${dy * 0.4 + 40}px, 0) rotate(${(liked ? 1 : -1) * 24}deg)`

    // Only the latest decision can be taken back: drop the previous anchor.
    this.lastDecision?.placeholder.remove()
    const placeholder = document.createComment("swiped")
    card.before(placeholder)
    setTimeout(() => card.remove(), 450)
    this.lastDecision = { card, placeholder }
    this.undoTarget.disabled = false

    vibrate(superlike ? [10, 30, 10] : (liked ? 12 : 6))
    if (superlike) this.superlikesValue = Math.max(0, this.superlikesValue - 1)
    this.#layout()

    try {
      const result = await request(this.urlValue, { method: "POST", body: { dog_id: card.dataset.dogId, liked, superlike } })
      if (typeof result?.superlikes_left === "number") this.superlikesValue = result.superlikes_left
      if (result?.match) {
        // A match cannot be taken back.
        this.lastDecision = null
        this.undoTarget.disabled = true
        this.#celebrate(card, result.chatroom_url)
      }
    } catch {
      // Not saved (offline, quota reached…): put the card back.
      this.lastDecision = null
      this.undoTarget.disabled = true
      this.#restore(card, placeholder)
    }
  }

  #restore(card, placeholder = this.lastDecision?.placeholder) {
    const anchor = placeholder?.isConnected ? placeholder : null
    if (anchor) anchor.replaceWith(card)
    else this.stackTarget.prepend(card)

    delete card.dataset.decided
    card.classList.remove("is-leaving")
    this.#reset(card)
    this.#layout()
    if (!this.lastDecision) this.undoTarget.disabled = true
  }

  #nudge(card, direction) {
    card.animate([
      { transform: "translateX(0)" }, { transform: `translateX(${direction * 8}px)` }, { transform: "translateX(0)" }
    ], { duration: 180, easing: "ease-out" })
  }

  #shake(element) {
    element?.animate([
      { transform: "translateX(0)" }, { transform: "translateX(-6px)" }, { transform: "translateX(6px)" }, { transform: "translateX(0)" }
    ], { duration: 260 })
    vibrate([8, 30, 8])
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
    if (event.key === "ArrowUp") this.superlike()
    if (event.key === "Backspace") this.undo()
  }
}
