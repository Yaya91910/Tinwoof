export function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return

  window.addEventListener("load", () => {
    if (document.querySelector("meta[name='service-worker']")?.content === "enabled") {
      navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {})
    } else {
      unregisterServiceWorkers()
    }
  })
}

// A worker left over from an earlier run would keep intercepting requests: remove it and its caches.
async function unregisterServiceWorkers() {
  const registrations = await navigator.serviceWorker.getRegistrations()
  await Promise.all(registrations.map((registration) => registration.unregister()))
  if (registrations.length === 0 || !("caches" in window)) return

  const keys = await caches.keys()
  await Promise.all(keys.filter((key) => key.startsWith("tinwoof-")).map((key) => caches.delete(key)))
  window.location.reload()
}

// Chrome fires `beforeinstallprompt` once, possibly before any controller is connected.
export function captureInstallPrompt() {
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault()
    window.tinwoofInstallPrompt = event
    document.dispatchEvent(new CustomEvent("pwa:installable"))
  })

  window.addEventListener("appinstalled", () => {
    window.tinwoofInstallPrompt = null
    document.dispatchEvent(new CustomEvent("pwa:installed"))
  })
}

// Stops the loading shimmer behind photos once they are displayed.
export function markLoadedImages() {
  const mark = (image) => image.classList.add("is-loaded")
  document.addEventListener("load", (event) => { if (event.target.tagName === "IMG") mark(event.target) }, true)
  document.addEventListener("turbo:load", () => {
    document.querySelectorAll("img").forEach((image) => { if (image.complete && image.naturalWidth) mark(image) })
  })
}

export function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
}

export function isIos() {
  return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
}
