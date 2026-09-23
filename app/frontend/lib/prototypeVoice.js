// PROTOTYPE — voice prototype (#388), branch prototype/voice only.
import { page } from "@inertiajs/svelte"

// The sample string in the current voice, or the original when no voice is set.
export const voiced = (key, original, vars = {}) => {
  const s = page.props.voice?.strings?.[key]
  if (!s) return original
  return s.replace(/\{(\w+)\}/g, (_, k) => vars[k] ?? "")
}
