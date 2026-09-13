# The term sheet: three registers

Throwaway. For [#373](https://github.com/MattMencel/bizlaw/issues/373), which asks
whether the four-column table that shipped in #344 is the wrong form for the
centre of the draft — [#315](https://github.com/MattMencel/bizlaw/issues/315)
asked for the other Side's last committed Offer in **redline** and the Client's
aspiration as a **margin note**, and nobody has ever drawn that. The rough on
[`prototype/day-grammar-paper`](https://github.com/MattMencel/bizlaw/tree/prototype/day-grammar-paper)
called its section "Redline against their last committed offer" and then drew
the same four columns, so the register named in the prose has never been looked
at.

Sub-shape A: the variants are mounted on the real route, against the real seed,
inside the real draft. `?variant=A|B|C` on `/demo/:run(/:seat)`, with a bar at
the foot of the page and `←`/`→` to cycle. It is gated on `import.meta.env.DEV`,
so it exists only under `bin/vite dev`.

## The three

- **A — the table, as shipped.** The control. Term / Ours / Theirs / What she
  asked for.
- **B — redline in place, true margin.** One ruled line per Term. Their position
  struck through before it, ours written on the line, the Client's in a gutter
  past a vertical rule. Still a `<table>`, with a visually hidden `<thead>`.
- **C — numbered articles.** The instrument itself: seven articles of a draft
  agreement, the operative words redlined inside the sentence, the Client's note
  in the margin beside the article. **The seven sentences are invented in the
  component.** The engine knows a Term's key and nothing else, so C is not a
  thing that can land as C — it is a picture of what the register would be if a
  Term carried authored clause text, which is
  [#343](https://github.com/MattMencel/bizlaw/issues/343) and out of this map.

## Running it

```bash
bin/rails demo:seed
bin/dev
```

Then `http://localhost:3000/demo/day-3?variant=B`.

Three page states are worth flipping through, and the seed only gives two:

| State | How |
| --- | --- |
| Day 3 as the player finds it | `/demo/day-3` — **our whole side of the sheet is silent** |
| Day 3 with a draft on our table | `bin/rails runner prototype/term-sheet-redline/stage.rb`, then reload |
| The Day 1 cold open | `/demo/cold-open` — identical in all three; `empty_state` short-circuits before any register |

`bin/rails demo:seed` undoes the staging.

`shots/` holds the three at the staged state, so the comparison survives without
a running server.

## What the looking found

Written up in full on the ticket. In short: the seeded Day 3 cannot answer the
question on its own, because the player has taken no position and a redline
needs two sides; #373's second complaint does not survive reading the shipped
component, and the real defect underneath it is a vocabulary one; B's ruled
blank is a picture and had to be given hidden text before a screen reader could
tell it from a cell it had skipped.
