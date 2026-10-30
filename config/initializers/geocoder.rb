# Server-side geocoding of the dogs' favourite walk spots, used when an address is typed
# without picking a suggestion. Photon (OpenStreetMap) is free and needs no API key.
Geocoder.configure(
  lookup: :photon,
  photon: { host: ENV.fetch("PHOTON_HOST", "photon.komoot.io") },
  language: :fr,
  units: :km,
  distances: :spherical,
  timeout: 3,
  use_https: true,
  http_headers: { "User-Agent" => "Tinwoof (https://github.com/Yaya91910/Tinwoof)" }
)
