# Prototype — three registers, one negotiation beat

Throwaway. Answers [#299](https://github.com/MattMencel/bizlaw/issues/299): *which
register is this game drawn in, and does the boardroom still win once it has real
competition?* Not production code — no tests, no persistence, authored stubs only.

Compare against [`prototype/negotiation-beat`](../negotiation-beat), which is the same
beat in three *stagings* of one register. This is three registers of the same beat.

## Run it

Double-click `index.html`. No server, no build, no network.

Switch registers with the bar at the bottom or the `←` / `→` keys. The bar also flips
the two probes the comparison needs: the **Band** (`firm` / `ready`, so you can check the
same Client is recognisable across both) and the **Docket** (Day 4 / empty, because the
empty state is the tutorial). `?register=A|B|C`, `?band=ready`, `?docket=empty` and
`?chrome=off` all work from the URL — the last one hides the bar for screenshots.

## The beat

Day 4 of *Whitfield v. Arrowmark Logistics*. You are **Priya Nair**, plaintiff Side,
Team Kestrel. You have staged an Offer — $185,000, a written apology, an unqualified
neutral reference — with three Exhibits riding it, and the commit control in your hand
is dead, because the Second is not yours to give.

Every register carries the same six things, so the comparison is about register and not
about scope:

- the Reaction Band at a glance, and the same Client recognisable across both Bands
- the Second as a present, disabled control naming who could give it
- Exhibits riding the Offer — including the Warehouse Safety Audit, which bears only on
  Training, lands irrelevant against this Offer, and is still spent and still served
- the Terms Board — your position, their last committed Offer, your Client's aspiration
- an empty Docket that says what a Docket would hold
- Attribution on every spend

## Canon the ticket predates

`CONTEXT.md` moved after #299 was written, and the mocks follow `CONTEXT.md`:

- **The Terms Board never shows Par.** The third marker is the Client's **aspiration**,
  authored per Client per Term and **sparse** — Neutral reference and NDA carry no
  aspiration marker at all. The other Side's track is their **last committed Offer read
  whole**: Training and Policy change are *silent* there, not zero.
- **There are two Reaction Bands, `firm` and `ready`** — not the eight expression states
  [#259](https://github.com/MattMencel/bizlaw/issues/259) sized. One face needs to carry
  a two-value signal, which is a much lower bar than #267 was costing against.
- **Only your own Client is expressive.** Marcus and Eleanor carry one authored
  expression each, fixed for the Simulation, because a face that reacted honestly would
  give away what a Consult is charged for.

## The three registers

- **A — The Boardroom.** The incumbent, scoped exactly as
  [#267](https://github.com/MattMencel/bizlaw/issues/267) costed it: avataaars bust
  reskin, business dress, the table faked with a foreground prop layer, two busts angled
  toward each other, your own Client large in the near-left foreground. The Offer sits in
  a thin dock; the Terms Board is a panel that covers the room when you open it.
- **B — The Console.** A CRT terminal: phosphor on black, monospace, box-drawn panels,
  everything diegetic as a screen the firm's case system draws. The cast is DiceBear
  `pixel-art` at 44px on the same `@dicebear/core` pipeline, so #267's pipeline decision
  survives untouched. No scene, so no commission and no faked table.
- **C — The Paper.** No characters. The game is the file: letterhead, exhibit tabs
  clipped to a draft, a redlined term sheet, a service stamp, a countersignature block
  with one line signed and one blank and greyed, a docket that is a docket, and the
  Client's Band as the tone of a typed memo.

## Rebuilding

```bash
npm install && npm run build
```

`build.mjs` renders the cast twice — avataaars for A, pixel-art for B — and concatenates
`src/` into `index.html`. **Edit `src/`, not `index.html`.**

Art provenance: [`fangpenlin/avataaars`](https://github.com/fangpenlin/avataaars)
(MIT, © 2017 Pablo Stanley, Fang-Pen Lin) and DiceBear `pixel-art` (CC0), both rendered
through `@dicebear/core` (MIT, © Florian Körner).
