# Prototype — one negotiation beat on screen

Throwaway. Answers [#264](https://github.com/MattMencel/bizlaw/issues/264): *what does one
negotiation beat actually look like on screen, and can a boardroom carry the expressiveness
the game needs?* Not production code — no tests, no persistence, stubbed reactions.

## Run it

Double-click `index.html`. No server, no build, no network.

Switch variants with the bar at the bottom, the `←` / `→` arrow keys, or `?variant=A|B|C`.
`?chrome=off` hides the bar for screenshots. The **state** button dumps the full in-memory
state after every action.

## The beat

Day 4 of *Whitfield v. Arrowmark Logistics*. You are Tom Ellis on the plaintiff Side.
Priya has **staged an Offer** — $185,000 plus a written apology and a neutral reference —
and it needs your **Second**. Before you give it, you choose which **Exhibits ride it**.
Then it lands, and three NPCs react: opposing counsel, their client, and your own.

Reactions are authored decision logic keyed on how many Exhibits rode the Offer. No model
anywhere in this file.

## The three variants

Each takes a different position on what carries the beat.

- **A — The Table.** The null hypothesis. A wide, mostly symmetrical boardroom; the two
  opponents across the table cut at the chest by the near edge, your own client large in
  the left foreground. Faces and staging do all the work; the Offer sits in a thin dock.
  If this reads, nothing more is needed.
- **B — The Terms Board.** Objects carry it. The room shrinks to a reaction strip and the
  screen becomes the table itself: a Terms board where each Term is a track with your
  position, theirs and Par, plus the Case File as paper on the left and the Docket on the
  right. Seconding moves the markers. Tests whether small faces plus moving documents beat
  big faces alone.
- **C — The Cut.** Dialogue-driven close-ups, the *Good Coffee, Great Coffee* register.
  One face fills the frame, the camera cuts between speakers, and the Second is a dialogue
  choice. Advance with click or space. Tests whether cutting beats a wide static room.

## Art

avataaars, six composed expressions per character (neutral, pleased, wary, skeptical,
insulted, resigned) over one unchanged head — the mechanic
[#259](https://github.com/MattMencel/bizlaw/issues/259) recommended. Rendered at build time
and inlined, so the page needs no network.

Provenance: art from [`fangpenlin/avataaars`](https://github.com/fangpenlin/avataaars)
(MIT, © 2017 Pablo Stanley, Fang-Pen Lin), rendered through `@dicebear/core`
(MIT, © Florian Körner).

## Rebuilding the art

```bash
npm install && npm run build
```

`build.mjs` renders the cast and inlines it into `index.html` from `template.html`.
**Edit `template.html`, not `index.html`.**
