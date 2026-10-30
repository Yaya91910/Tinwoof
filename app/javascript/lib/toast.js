// Shows a transient toast, styled like the server-rendered flashes.
export function toast(message) {
  const container = document.getElementById("toasts")
  if (!container) return

  const element = document.createElement("div")
  element.className = "toast toast--notice"
  element.setAttribute("role", "status")
  element.dataset.controller = "toast"
  const text = document.createElement("p")
  text.className = "toast__text"
  text.textContent = message
  element.append(text)
  container.append(element)
}
