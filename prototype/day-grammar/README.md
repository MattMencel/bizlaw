# Prototype — the Day's grammar in the paper register

Throwaway. Answers [#315](https://github.com/MattMencel/bizlaw/issues/315) as recut:
*what are the surfaces, and how does a student move between them, now that the game is
the file?* Not production code — no tests, no persistence, authored stubs only.

## Why the ticket was recut

#315 was written as **"the two-room grammar, roughed out"** and asked for the Firm, the
Boardroom, the door between them and the Close-up. [#299](https://github.com/MattMencel/bizlaw/issues/299)
closed 18 minutes before [the map](https://github.com/MattMencel/bizlaw/issues/312) was
charted and deleted all four: the register is **the paper**, "C plus one face". The map's
Destination and #315 were both written against canon that #299 had already replaced, and
neither argues against it.

So the question survives and its premise does not. What remains genuinely open is
everything that was never about rooms — where the four record surfaces sit, how the
Morning Briefing arrives and is got back, and where the countersignature block lives.

**The register is not up for judgement here.** All three variants are drawn in the same
paper idiom, deliberately, so that what differs is grammar. Compare against
[`prototype/three-registers`](https://github.com/MattMencel/bizlaw/tree/prototype/three-registers),
which is the same beat in three *registers*; this is one register in three *grammars*.

## Run it

Double-click `index.html`. No server, no build, no network, no npm.

Switch grammars with the bar at the bottom or the `←` / `→` keys. The bar also flips the
one probe that matters: **Day 3** (the map's main path) against **Day 1** (the cold open,
the only Day on which every section is empty and the empty state has to be the tutorial).
`?variant=A|B|C`, `?day=1` and `?chrome=off` all work from the URL.

## The beat

Day 3 of 10, *Whitfield v. Arrowmark Logistics*, plaintiff Side, Team Kestrel. You are
**Dana Whitcombe**. Overnight the defendant committed their Day 3 offer and served you
the supervisor's deposition, so you open the Day already argued at. You have drawn a
draft — $180,000, an apology, reinstatement, a neutral reference — with the claimant's
personnel file clipped to it as an Exhibit, and you drew it, so the countersignature line
is the dead one.

Shapes and vocabulary follow [`app/reads/`](../../app/reads) and
[`db/cases/reference.yml`](../../db/cases/reference.yml) rather than being invented:

- the exchange half is **2 points**, and the draft plus its one Exhibit costs exactly 2,
  quoted as **one price** ([#291](https://github.com/MattMencel/bizlaw/issues/291))
- `retain_expert` is **present and refused** with its reason, because hiding what an
  Action costs makes the Budget unplannable
- the deposition is **served**, so it carries no Exhibit property — the same authored
  document that is ammunition for the defendant
- the Terms Board never shows Par; the third column is the Client's **sparse** aspiration,
  and their column is one offer read whole, so a Term they did not address is *silent*
- what a Consult hands back is left as a deliberate hole — that is
  [#314](https://github.com/MattMencel/bizlaw/issues/314)
- the one surviving face is a placeholder box labelled as
  [#316](https://github.com/MattMencel/bizlaw/issues/316)'s question, not an answer to it

## The three grammars

- **A — The Folder.** The surfaces are peers and you visit exactly one at a time; tabs
  down the left edge of one folder, one full sheet in view. There is no second place to
  be — the draft is the sheet behind the Terms tab, and executing it is a signature on
  that sheet. The Briefing is the first tab and stays a tab all Day, so it is never
  dismissed and never lost.
- **B — The Desk.** Everything is one kind of thing: a paper. A permanent left index runs
  the Docket's acts and the Case File's documents together in one chronological list —
  both answer *what has happened* — with the four standing instruments pinned above it.
  The right side reads whichever you picked. Nothing ever covers anything. The Briefing
  arrives at the top of the run each Day marked `new`, and stays in the run once read.
- **C — The Working Draft.** The draft is the page, always. The term sheet holds the
  centre with the aspiration in the margin and their offer struck through in redline;
  the countersignature block sits under it and the Action slip along the foot. The Case
  File and the Docket are the **back** of the same instrument — you turn the page over
  rather than going anywhere. The Briefing is the draft's front matter. The deal is never
  off screen.

## What each one is betting

- **A** bets that a student who can only see one thing at a time is a student who is not
  lost. It costs the side-by-side read — you cannot hold the Action Board's prices next to
  the Docket's lead times, which is the planning the Budget exists to teach.
- **B** bets that collapsing *what we know* and *what we have done* into one run is the
  honest shape, since both are the record and the split was two tables' problem, not the
  student's. It costs the draft its primacy: the deal is one paper among twenty.
- **C** bets that the game is the negotiation and everything else is apparatus. It costs
  the Case File and Docket their standing, and the flip is a real risk — a surface behind
  a gesture is a surface half the Team never turns to.
