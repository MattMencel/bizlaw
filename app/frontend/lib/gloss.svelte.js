// The gloss on first contact (`docs/design/voice.md` § Where a gloss sits).
//
// A page provides one glossary per face it shows: the terms that face glosses,
// each with the sites its note may sit at, in order of preference. A site is a
// piece of text a component marks with `<Glossed at=…>`, and every occurrence of
// an anchored word in a mounted site registers here. Exactly one registration
// per term *carries* the note: the most preferred site the page actually
// rendered, and where that site repeats, the first of them in reading order.
//
// It is decided on the page rather than in Ruby because only the page knows what
// it printed. An empty state that has filled up, a rail that is not there, a
// Docket with no Consult on it — the composer would have to re-derive every one
// of those conditions to say where first contact falls. Nothing is remembered
// between visits: the empty states are the tutorial, so every visit glosses
// again and two teammates read the same sheet.

import { getContext, setContext } from "svelte"

const KEY = Symbol("glossary")

const escape = (word) => word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")

const inReadingOrder = (a, b) =>
  a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1

class Glossary {
  #source
  #sites = $state.raw([])

  constructor(source) {
    this.#source = source
  }

  get #glossary() {
    return this.#source() ?? { entries: [] }
  }

  get heading() {
    return this.#glossary.heading
  }

  // The anchors that sit in one site's text: which term, which word, and how
  // preferred this site is for that term.
  anchorsAt(at) {
    return this.#glossary.entries.flatMap((entry) =>
      entry.sites
        .map((site, rank) => ({ ...site, rank }))
        .filter((site) => site.at === at)
        .map(({ word, rank }) => ({ term: entry.term, word, rank }))
    )
  }

  add(term, rank, el) {
    const site = { term, rank, el }
    this.#sites = [...this.#sites, site]
    return () => (this.#sites = this.#sites.filter((s) => s !== site))
  }

  carrier(term) {
    const candidates = this.#sites.filter((s) => s.term === term)
    if (!candidates.length) return null
    const best = Math.min(...candidates.map((s) => s.rank))
    return candidates
      .filter((s) => s.rank === best)
      .map((s) => s.el)
      .sort(inReadingOrder)[0]
  }

  // Every term this face is glossing right now, in the order it is met.
  get glossed() {
    return this.#glossary.entries
      .map((entry) => ({ ...entry, el: this.carrier(entry.term) }))
      .filter((entry) => entry.el)
      .sort((a, b) => inReadingOrder(a.el, b.el))
  }
}

// `source` is a function so a page with two faces can hand over whichever one
// is showing; the sites of the face it turned away from unmount with it.
export function provideGlossary(source) {
  return setContext(KEY, new Glossary(source))
}

export const useGlossary = () => getContext(KEY)

// A site's text, cut at each anchored word it holds. The first whole-word
// occurrence of each is the one that can carry; an anchor whose word is not in
// the text glosses nothing here.
export function split(text, anchors) {
  const found = anchors
    .map((anchor) => {
      const match = new RegExp(`\\b${escape(anchor.word)}\\b`).exec(text)
      return match && { ...anchor, index: match.index }
    })
    .filter(Boolean)
    .sort((a, b) => a.index - b.index)

  const parts = []
  let at = 0
  for (const anchor of found) {
    if (anchor.index < at) continue
    if (anchor.index > at) parts.push({ text: text.slice(at, anchor.index) })
    parts.push(anchor)
    at = anchor.index + anchor.word.length
  }
  if (at < text.length) parts.push({ text: text.slice(at) })
  return parts
}
