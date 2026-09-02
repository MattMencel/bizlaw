# The Rubric

The grade students receive. Extracted from the throwaway Rails app's
`app/services/performance_calculator.rb` before that app was deleted in
[#283](https://github.com/MattMencel/bizlaw/issues/283), and restated in the shape
[#262](https://github.com/MattMencel/bizlaw/issues/262) settled on.

The rubric is the professor's, not the developer's. The weights below are the
carry-over Map [#257](https://github.com/MattMencel/bizlaw/issues/257) named as the
one thing worth keeping from the old app; how each dimension is *measured* was
rebuilt by #262 and is recorded here as the engine's target, not as a description
of anything that currently runs.

## Weights

| Dimension | Points | Scored per |
|---|---|---|
| Settlement quality | 40 | Team |
| Legal strategy | 30 | Team |
| Collaboration | 20 | Student |
| Efficiency | 10 | Team |
| **Total** | **100** | |
| Creative terms (bonus) | up to 10 | Team |

The creative-terms bonus sits **above** the 100 rather than inside it. Three
dimensions are Team scores; collaboration alone is per-student. No dimension
carries a participation floor — a student who does nothing inherits the Team's
three dimensions and no more.

## Visibility

Published to students in full on day one. **No rubric-derived number is ever
visible to a student before the Instructor releases it.** The Instructor sees live
provisional scores throughout.

Provisional scores are recomputed from the record every time they are read, so an
Instructor's adjustment shows immediately. Release writes each score down for
good, alongside the weights and the Par it was measured against, so a grade queried
a year later is answered from what the student was actually shown.

## How each dimension is measured

**Settlement quality (40)** is scored against an authored **Par** — the settlement
value the Case's authors consider well-negotiated for one Side — and never
head-to-head. Par is per-Side and not zero-sum: both Sides can score full marks on
the same settlement. The forty points ramp from a floor a quarter of the Client's
bound short of Par, reaching full marks at Par and beyond and nothing at or below
the floor. The floor is immobile, because the Client's live reservation point is
moved by the *opposing* Team's Exhibits, and ramping from it would let one Side's
grading scale be set by how hard its opponent worked.

**Legal strategy (30)** is scored from the **Docket** — the record of what the Team
spent and what it played — not from keyword-matching student prose. Relevance hits
are what it counts: an Exhibit played into an Offer that touches the Terms it bears
on. This is the same objection that killed the LLM grading digest in
[#274](https://github.com/MattMencel/bizlaw/issues/274); text is never evidence.

**Collaboration (20)** reads distribution across the Docket and the deliberation
threads. When a Section enables optional **Peer Evaluation**, it supplies 6 of the
20 and the Docket supplies the remaining 14; when off, all 20 come from the Docket.
The app proposes; the Instructor renders.

**Efficiency (10)** counts Actions that paid off. A played Exhibit is paid off; an
unplayed one is neutral rather than penalized, capped. Speed folds in here — it is
not a separate bonus.

**Creative terms (bonus, up to 10)** rewards non-monetary Terms in a settlement.
Because Terms are authored per Case with a private valuation per Client, this reads
the Offer's composition rather than scanning free text.

## What the old calculator did differently

The old `PerformanceCalculator` established the weights and nothing else survives
it. Recorded here so the differences are deliberate rather than forgotten:

- **Speed was a separate 10-point bonus.** #262 folded it into efficiency. The old
  version scored raw response latency in hours, which graded students on when they
  happened to be at a keyboard in an asynchronous game.
- **Settlement quality was scored against a live client-satisfaction range**
  (`ClientRangeValidationService`), not an authored Par. That made the grading
  scale movable by play, which is precisely what the immobile floor now prevents.
- **Legal strategy keyword-matched student prose** — counting occurrences of
  `"precedent"`, `"case law"` and `"statute"` in an offer's justification, plus a
  regex for citation-shaped strings. #262 replaced this with the Docket.
- **Collaboration used message-length heuristics** (substantial messages counted as
  those over 50 characters and not matching `/^(ok|yes|no|sure)$/i`) against a
  messaging system that was never implemented, so the method returned an empty
  array in production.
- **Creative terms keyword-matched free text** against a fixed indicator list, and
  awarded an "innovation" point for prose containing the words *innovative*,
  *creative*, *unique* or *novel*.
- **Participation floors existed** — collaboration started at 8 of 20 points for
  any student with at most two recorded actions. #262 dropped every floor.
- **Every dimension was per-student.** Three of the four are now Team scores.
