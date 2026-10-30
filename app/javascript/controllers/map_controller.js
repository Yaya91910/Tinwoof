import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { loadMapLibre, mapStyle } from "../lib/maplibre"

const PARIS = [2.3522, 48.8566]
const BRAND = "#ff4d6d"

// Two modes:
// - "explore": full-screen map, dogs streamed as clustered GeoJSON for the visible area.
// - "static": a small preview map with a fixed set of markers.
export default class extends Controller {
  static targets = ["canvas", "count", "sheet", "sheetLink", "sheetPhoto", "sheetName", "sheetMeta"]
  static values = { mode: String, url: String, center: Array, user: Array, markers: Array, zoom: Number }

  async connect() {
    const container = this.hasCanvasTarget ? this.canvasTarget : this.element

    let maplibregl
    try {
      maplibregl = await loadMapLibre()
    } catch {
      return this.#unavailable(container, "Carte indisponible hors connexion.")
    }
    if (!this.element.isConnected) return

    this.maplibregl = maplibregl
    this.markers = new Map()
    this.map = new maplibregl.Map({
      container,
      style: mapStyle(),
      center: this.centerValue.length ? this.centerValue : PARIS,
      zoom: this.hasZoomValue ? this.zoomValue : (this.#explore ? 12.5 : 14),
      pitch: this.#explore ? 30 : 0,
      attributionControl: false,
      cooperativeGestures: !this.#explore
    })
    this.map.addControl(new maplibregl.AttributionControl({ compact: true }))

    if (this.#explore) {
      this.#setupExplore()
    } else {
      this.#setupStatic()
    }
  }

  disconnect() {
    this.abort?.abort()
    this.map?.remove()
    this.map = null
  }

  closeSheet() {
    this.sheetTarget.hidden = true
  }

  get #explore() {
    return this.modeValue === "explore"
  }

  #setupExplore() {
    const geolocate = new this.maplibregl.GeolocateControl({
      positionOptions: { enableHighAccuracy: true },
      trackUserLocation: true,
      showAccuracyCircle: true
    })
    this.map.addControl(geolocate, "bottom-right")
    this.map.addControl(new this.maplibregl.NavigationControl({ showZoom: false, visualizePitch: true }), "bottom-right")

    // Zoomed out, the map becomes a 3D globe.
    this.map.on("style.load", () => this.map.setProjection({ type: "globe" }))

    this.map.on("load", async () => {
      this.map.addSource("dogs", {
        type: "geojson",
        data: { type: "FeatureCollection", features: [] },
        cluster: true,
        clusterRadius: 48,
        clusterMaxZoom: 15
      })
      this.map.addLayer({
        id: "clusters",
        type: "circle",
        source: "dogs",
        filter: ["has", "point_count"],
        paint: {
          "circle-color": BRAND,
          "circle-opacity": 0.92,
          "circle-stroke-width": 4,
          "circle-stroke-color": "rgba(255,255,255,0.85)",
          "circle-radius": ["step", ["get", "point_count"], 20, 10, 26, 50, 34]
        }
      })
      this.map.addLayer({
        id: "cluster-count",
        type: "symbol",
        source: "dogs",
        filter: ["has", "point_count"],
        layout: { "text-field": ["get", "point_count_abbreviated"], "text-size": 14, "text-font": ["Noto Sans Bold"] },
        paint: { "text-color": "#ffffff" }
      })

      this.map.on("click", "clusters", (event) => this.#zoomIntoCluster(event.features[0]))
      this.map.on("mouseenter", "clusters", () => (this.map.getCanvas().style.cursor = "pointer"))
      this.map.on("mouseleave", "clusters", () => (this.map.getCanvas().style.cursor = ""))
      this.map.on("render", () => this.#syncPhotoMarkers())
      this.map.on("moveend", () => this.#scheduleFetch())
      this.map.on("click", (event) => {
        if (!event.originalEvent.target.closest(".photo-marker")) this.closeSheet()
      })

      await this.#fetchDogs()
      if (navigator.permissions?.query) {
        const status = await navigator.permissions.query({ name: "geolocation" }).catch(() => null)
        if (status?.state === "granted") geolocate.trigger()
      }
    })
  }

  #setupStatic() {
    this.map.on("load", () => {
      // Start with the compact attribution folded: the (i) button still reveals it.
      this.element.querySelector(".maplibregl-ctrl-attrib")?.classList.remove("maplibregl-compact-show")

      const bounds = new this.maplibregl.LngLatBounds()
      this.markersValue.forEach((marker) => {
        new this.maplibregl.Marker({ element: this.#photoMarker(marker), anchor: "bottom" })
          .setLngLat([marker.lng, marker.lat])
          .addTo(this.map)
        bounds.extend([marker.lng, marker.lat])
      })
      if (this.hasUserValue && this.userValue.length) {
        const dot = document.createElement("div")
        dot.className = "user-dot"
        new this.maplibregl.Marker({ element: dot }).setLngLat(this.userValue).addTo(this.map)
        bounds.extend(this.userValue)
        this.map.fitBounds(bounds, { padding: 56, maxZoom: 15, duration: 0 })
      }
    })
  }

  #scheduleFetch() {
    clearTimeout(this.fetchTimer)
    this.fetchTimer = setTimeout(() => this.#fetchDogs(), 250)
  }

  async #fetchDogs() {
    if (!this.map) return
    this.abort?.abort()
    this.abort = new AbortController()

    const bounds = this.map.getBounds()
    const bbox = [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()].map((n) => n.toFixed(5)).join(",")
    try {
      const response = await fetch(`${this.urlValue}?bbox=${bbox}`, {
        headers: { Accept: "application/json" },
        signal: this.abort.signal
      })
      const geojson = await response.json()
      this.map?.getSource("dogs")?.setData(geojson)
      this.#renderCount(geojson.features.length)
    } catch (error) {
      if (error.name !== "AbortError") this.#renderCount(null)
    }
  }

  #renderCount(count) {
    if (!this.hasCountTarget) return
    if (count === null) this.countTarget.textContent = "Connexion perdue"
    else if (count === 0) this.countTarget.textContent = "Aucun chien ici, dézoomez"
    else this.countTarget.textContent = `${count} chien${count > 1 ? "s" : ""} dans la zone`
  }

  // Unclustered points are drawn as HTML photo markers (recycled as the map moves).
  #syncPhotoMarkers() {
    if (!this.map.getSource("dogs") || !this.map.isSourceLoaded("dogs")) return

    const visible = new Map()
    this.map.querySourceFeatures("dogs").forEach((feature) => {
      if (!feature.properties.cluster) visible.set(feature.properties.id, feature)
    })

    visible.forEach((feature, id) => {
      if (this.markers.has(id)) return
      const element = this.#photoMarker({ ...feature.properties })
      element.addEventListener("click", () => this.#openSheet(feature.properties))
      const marker = new this.maplibregl.Marker({ element, anchor: "bottom" })
        .setLngLat(feature.geometry.coordinates)
        .addTo(this.map)
      this.markers.set(id, marker)
    })

    this.markers.forEach((marker, id) => {
      if (visible.has(id)) return
      marker.remove()
      this.markers.delete(id)
    })
  }

  #photoMarker({ photo, name, mine }) {
    const element = document.createElement("button")
    element.type = "button"
    element.className = `photo-marker${mine === true || mine === "true" ? " photo-marker--mine" : ""}`
    element.setAttribute("aria-label", name)
    if (photo) {
      const image = document.createElement("img")
      image.src = photo
      image.alt = ""
      image.loading = "lazy"
      element.append(image)
    } else {
      element.classList.add("photo-marker--empty")
      element.textContent = "🐶"
    }
    return element
  }

  async #zoomIntoCluster(feature) {
    const zoom = await this.map.getSource("dogs").getClusterExpansionZoom(feature.properties.cluster_id)
    this.map.easeTo({ center: feature.geometry.coordinates, zoom: zoom + 0.5 })
  }

  #openSheet(dog) {
    if (!this.hasSheetTarget) return Turbo.visit(dog.url)

    this.sheetLinkTarget.href = dog.url
    this.sheetPhotoTarget.src = dog.photo || ""
    this.sheetPhotoTarget.hidden = !dog.photo
    this.sheetNameTarget.textContent = dog.name
    this.sheetMetaTarget.textContent = dog.breed
    this.sheetTarget.hidden = false
  }

  #unavailable(container, message) {
    container.classList.add("map-unavailable")
    container.textContent = message
  }
}
