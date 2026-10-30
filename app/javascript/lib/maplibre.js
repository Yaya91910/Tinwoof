const VERSION = "5.24.0"
const BASE = `https://cdn.jsdelivr.net/npm/maplibre-gl@${VERSION}/dist`
let loading

// MapLibre GL is ~800 kB: it is only fetched on pages that actually show a map.
export function loadMapLibre() {
  if (window.maplibregl) return Promise.resolve(window.maplibregl)

  loading ||= new Promise((resolve, reject) => {
    const css = document.createElement("link")
    css.rel = "stylesheet"
    css.href = `${BASE}/maplibre-gl.css`
    document.head.append(css)

    const script = document.createElement("script")
    script.src = `${BASE}/maplibre-gl.js`
    script.async = true
    script.onload = () => resolve(window.maplibregl)
    script.onerror = () => { loading = null; reject(new Error("MapLibre GL failed to load")) }
    document.head.append(script)
  })
  return loading
}

// Free, keyless OpenStreetMap vector tiles (openfreemap.org), matching the colour scheme.
export function mapStyle() {
  const dark = window.matchMedia("(prefers-color-scheme: dark)").matches
  return `https://tiles.openfreemap.org/styles/${dark ? "dark" : "liberty"}`
}
