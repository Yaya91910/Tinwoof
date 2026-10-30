export function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return

  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {})
  })
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

export function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
}

export function isIos() {
  return /iphone|ipad|ipod/i.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
}
