// PROTOTYPE — "Where does a gloss sit on first contact?" (#399), branch
// prototype/gloss-placement only. Throwaway.
//
// `?gloss=a|b|c|d` picks a placement; no param is the page as it is on main.
// First contact is decided structurally: the first site in reading order on
// this render claims the term. There is no per-student flag (reads.en.yml:
// "the empty state is the tutorial"), so every render glosses again.

// The glosses, in the voice spec's rule 5: what the word literally means.
export const GLOSSES = {
  execute: "sign it and send it to the other side; it can't be taken back",
  countersign: "sign off on it as well",
  exhibit: "a document we attach to an offer as evidence",
  served: "formally delivered to a side, which puts them on notice",
  depose: "question under oath, on the record"
}

export const VARIANTS = {
  o: "O — No glosses",
  a: "A — Inline, in the sentence",
  b: "B — Marginal note, left gutter",
  c: "C — Footnote at the foot of the front",
  d: "D — Definitions clause in the front matter"
}

export const variant = (() => {
  const v = new URLSearchParams(window.location.search).get("gloss")
  return v in VARIANTS ? v : "o"
})()

// Inline cannot hang a clause off a label or a button, so under A only prose
// can be first contact. Every other placement lets any site claim.
const canClaim = (kind) => variant !== "o" && (variant !== "a" || kind === "prose")

// term -> { n, id } for the site that claimed it. Reactive so the footnotes
// and the gutter can read it.
export const claims = $state({ list: [] })
const owners = new Map()

export function claim(term, kind) {
  if (!canClaim(kind) || owners.has(term)) return null
  const token = { term, n: claims.list.length + 1, id: `gloss-${term}` }
  owners.set(term, token)
  claims.list.push(token)
  return token
}

// A keyed block (the Draft remounts on every re-read) gives its claims back.
export function release(token) {
  if (!token || owners.get(token.term) !== token) return
  owners.delete(token.term)
  claims.list = claims.list.filter((t) => t !== token).map((t, i) => ({ ...t, n: i + 1 }))
  for (const t of claims.list) owners.set(t.term, t)
}

export const numberOf = (term) => claims.list.find((t) => t.term === term)?.n
