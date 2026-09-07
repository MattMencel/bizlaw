---
status: accepted
---

# The settlement beat is the executed instrument, and it ends the Simulation

[#299](https://github.com/MattMencel/bizlaw/issues/299) deleted the Close-up and
left the last thing a professor sees unspecified. A settlement deserves more
than a closed Day, and `app/reads/docket.rb:14` has been calling an Acceptance
"the Acceptance that ends the Simulation" while the code ends nothing at all:
`Offers::Accept` writes one row and calls nothing, and `Days::Close` opens the
following Day unconditionally, so a settled run today keeps opening Days and
handing out Action Budget.

Three decisions, taken together because each one is what makes the next
possible.

**An Acceptance ends the Simulation.** `CONTEXT.md` has always said a run goes
"from opening to settlement or its failure", and Arbitration is what a run ends
in "when it runs out of Days without a settlement" — two terminations, mutually
exclusive. `Simulation#settled?` is a fold over `offer_acceptances`, never a
column, per ADR 0002. Every seam that already asks `day.closed?` asks this too,
so no act lands into a finished run.

**The beat is paper, and the paper already exists as rows.** An Acceptance *is*
a countersignature on the other Side's instrument, and
[#315](https://github.com/MattMencel/bizlaw/issues/315) settled that the draft
is the page, always. So the beat is the accepted `committed_offers` row's own
term sheet, executed — both countersignature lines filled, an execution stamp —
rendered from `committed_offers`, `committed_offer_terms` and
`offer_acceptances`. Nothing new is written, and it becomes the page the file
rests on once the run is settled: the back still turns to the Case File and the
Docket, and the Action slip along the foot has nothing left to offer.

**The Client's beat rides it, carrying words and nothing computed.** Both Sides
get one, each from their own Client, on the one shared instrument. It carries
the face and no Reaction Band.

## Considered options

**An executed agreement in the Case File.** The natural reading, and the one the
question was framed around: the accepted Offer's Terms rendered onto a
`case_file_documents` row with no authored `case_documents` behind it. It is
wrong twice over. The Case File answers *what do we know* — an executed
agreement is not knowledge, it is the outcome, so it is a category error there
independent of any schema cost. And the schema cost is not small:
`case_file_documents.case_document_id` is `NOT NULL` behind a composite foreign
key to `case_documents (id, case_version_id)`, under a unique index on
`(side_id, case_document_id)`, with `title` and `body` delegated to the authored
row and `served?`, `exhibit?`, `playable?` and `bears_on?` all assuming one.
Making it nullable invents a fifth Provenance for the one document that came
from neither authoring nor service, and puts non-authored content in a table
whose every other row has an `:authored` parent.

**A Reaction Band on the beat, folded as of the Acceptance.** Free to compute —
it is ADR 0006's existing call with a different horizon — and still wrong.
*firm* and *ready* mean *willing to keep holding out*, which is moot the instant
the instrument is executed, and ADR 0006's argument for charging Action Budget
for a band is that it informs a decision. There is none left. A `ready` chip on
an executed agreement is a category error dressed as consistency.

**Telling the Team how the deal landed** — against the Client's aspiration, or
against their reservation point. Refused on two independent grounds. Settlement
Quality is rubric-derived and no rubric-derived number reaches a student before
Release. And a Section runs many concurrent Simulations on one Case: a Team that
settles on Tuesday and learns its Client's number hands it to a friend still
playing the same Case on Wednesday. Post-settlement is not post-exposure, which
is the whole reason the reservation point is the thing a Consult is charged for.

**One authored line per Client, undimensioned.** Rejected in favour of two —
took it, or had it taken. There is no Simulation seed
([#314](https://github.com/MattMencel/bizlaw/issues/314) deferred one with the
Event Deck) and a node spoken exactly once has a speak-count of zero forever, so
variants would be dead weight and always resolve to the first. The acceptance
role is the one dimension the act itself supplies, and "you took their number"
and "they took ours" are different feelings about identical terms — a professor
authoring the Case would write them differently. Cost is four lines per Case.

## Consequences

**`Days::Close` gains a fourth caller, and its comment is amended rather than
violated.** `Offers::Accept` calls it. The invariant that seam protects is *one
close path*, not *three callers* — a fourth routed through it is exactly what
the shape was built for, and the compare-and-set already handles racing a
deadline fire. Ordering is load-bearing: the `offer_acceptances` row is written
before `Close` runs, inside one transaction, so `settled?` is already true when
`Close` decides whether to open the following Day. Without that, the last act of
a settled run opens a Day nobody can play.

**ADR 0005's "nowhere else" narrows from a location to a count.** It placed the
one surviving face "where the Reaction Band lands, and nowhere else", and there
is no band here. `CONTEXT.md` already read it as a count — the Client's beat is
"the only place their portrait appears", and settlement is one of exactly two
places a Client speaks — and that reading wins. Exactly one Party is ever
portrayed; the beat is one surface with two occasions. This is the same kind of
narrowing ADR 0005 performed on ADR 0001's justification for Inertia.

**The commission gains one expression, which was already budgeted.**
[#312](https://github.com/MattMencel/bizlaw/issues/312)'s charting notes sized
the Team's own Client at "roughly three states plus a settlement beat". The
settlement expression is authored to the occasion rather than derived from a
band, which is a deliberate exception to the rule that expression follows the
band — there is no band to follow. It is **invariant**: the same face on every
settlement regardless of the terms, the Side, or who accepted. A Client whose
face falls at a bad deal is a free Settlement Quality read, which is the leak
this ADR spent its length refusing, arriving through the art instead of through
the copy.

**`Cases::Import` gains a gate.** A Case that does not supply both settlement
lines for both Clients does not import, as loudly as it refuses a Client with no
opening statement — the same enforcement-at-the-boundary shape ADR 0006 used for
a document authored behind `consult_client`.

**The accepted Side has no Morning Briefing to learn it from.** No Day opens
after a settlement, so the executed page is how a Team whose Offer was taken
finds out, on their next visit. That is a consequence of ending the Simulation
rather than a gap in the Briefing, and it is why both Sides read a beat rather
than only the one that acted.

**The Docket does not move.** `Docket::OFFER_ACCEPTED` already folds the
Acceptance in as one of the three acts with no cost, and an Acceptance remains
"the largest thing a Team ever does for nothing".
