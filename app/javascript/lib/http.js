function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.content
}

export async function request(url, { method = "GET", body, keepalive = false } = {}) {
  const response = await fetch(url, {
    method,
    keepalive,
    credentials: "same-origin",
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: body && JSON.stringify(body)
  })

  if (!response.ok) throw new Error(`${method} ${url} failed with ${response.status}`)
  return response.status === 204 ? null : response.json()
}

export function metaContent(name) {
  return document.querySelector(`meta[name='${name}']`)?.content
}
