export function vibrate(pattern) {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
  navigator.vibrate?.(pattern)
}
