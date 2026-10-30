const EARTH_RADIUS_M = 6371000

export function distanceInMeters([lng1, lat1], [lng2, lat2]) {
  const toRad = (deg) => (deg * Math.PI) / 180
  const dLat = toRad(lat2 - lat1)
  const dLng = toRad(lng2 - lng1)
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(a))
}

export function currentPosition(options = {}) {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: false,
      maximumAge: 5 * 60 * 1000,
      timeout: 15000,
      ...options
    })
  })
}

// Resolves to "granted" | "prompt" | "denied", or null when the Permissions API is unavailable (older Safari).
export async function geolocationPermission() {
  if (!navigator.permissions?.query) return null
  try {
    return await navigator.permissions.query({ name: "geolocation" })
  } catch {
    return null
  }
}

// Photon (photon.komoot.io): free OpenStreetMap geocoding built for search-as-you-type.
const PHOTON = "https://photon.komoot.io"

export async function reverseGeocode([lng, lat]) {
  const params = new URLSearchParams({ lon: lng, lat, lang: "fr", limit: 1 })
  try {
    const response = await fetch(`${PHOTON}/reverse?${params}`)
    const { features } = await response.json()
    const place = features?.[0]?.properties
    return place ? (place.locality || place.district || place.city || place.name || null) : null
  } catch {
    return null
  }
}

export async function forwardGeocode(query, { proximity, signal } = {}) {
  const params = new URLSearchParams({ q: query, lang: "fr", limit: 5 })
  if (proximity) {
    params.set("lon", proximity[0])
    params.set("lat", proximity[1])
  }
  const response = await fetch(`${PHOTON}/api?${params}`, { signal })
  const { features = [] } = await response.json()
  return features.map(({ properties: place, geometry }) => {
    const street = [place.housenumber, place.street].filter(Boolean).join(" ")
    const name = place.name || street || place.city
    const context = [place.name ? street : null, place.postcode, place.city || place.district, place.country]
      .filter(Boolean).filter((part, index, parts) => parts.indexOf(part) === index && part !== name).join(", ")
    return { label: [name, place.city].filter(Boolean).join(", "), name, context, coordinates: geometry.coordinates }
  })
}
