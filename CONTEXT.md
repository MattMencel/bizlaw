# Context

Glossary for the BizLaw negotiation simulation. Terms only — no implementation.

## Simulation

One complete run of one Case, from opening to settlement or its failure. Two Teams take opposing Sides. An Instructor starts it, sets its pace, and ends it. Runs over two to three weeks of wall-clock time and contains roughly 8–12 Days.

## Case

The authored dispute a Simulation runs on: the facts, the parties, the documents, and the private positions each Client holds. Data, not code. One Case can back many concurrent Simulations.

## Side

Plaintiff or defendant. A Side is a position in the dispute, not a group of people — the Team is the people. The two Sides are deliberately **asymmetric**: they have different action menus, because building pressure and containing exposure are different jobs.

## Team

The small group of students playing one Side. Three to five, and **flat** — no lead counsel, no researcher, no liaison. Every member has the same standing and the same Action menu; specialisation is a strategy a Team may choose, never a permission the game grants.

A Team acts as a single negotiating party: one shared state, one Action Budget, one set of committed Actions. Each student sees that state through their own view, so a Team sitting together and a Team working apart are playing the same Day.

## Day

**The unit of play.** A Day opens, the Team spends its Action Budget, and the Day closes. A Day is a unit of the *Simulation*, not of wall-clock time: a Team sitting together in class may burn a Day in twenty minutes, a Team working apart may take three evenings over it. Both are the same Day.

Not to be confused with the old app's *round*, which was a submission box holding one number per Side.

## Action Budget

What a Team has to spend within one Day. The scarce resource that makes preparation compete with negotiation — the tension the course is actually about.

## Action

One thing a Team spends Action Budget on. Making or revising an Offer is one Action among many; consulting the Client, deposing a witness, requesting documents, researching precedent and managing the press are others. **Consulting the Client costs Budget**, so a Team that never asks negotiates blind.

## Offer

A proposed settlement, with terms. The move that can end the Simulation if the other Side accepts it and the Client will take it.

An Offer is **staged** before it is committed: visible to the whole Team, revisable, costing nothing until it lands.

## Second

A teammate's confirmation, and the only gate inside a Team. An Offer or an Acceptance lands only when a member other than the one who staged it confirms it. Nothing else in the game requires one — the preparation half stays ungated.

A Team whose other members are absent can stage an Offer it cannot commit. That is not a mechanic; it is an Instructor **waiver** of the Second, granted to one Team for one Day and recorded in the Docket as an Instructor action. The Instructor never Seconds on a Team's behalf — Attribution would then name someone who did not take the position.

## Docket

The Team's chronological record of Actions taken: what was spent, which member spent it, and the Day its result lands. Answers *what have we done and what is coming*. Visible to the whole Team, naming who acted; it carries no per-member totals or contribution scores.

## Attribution

The record of which member took an Action. Attached to every spend. It is what lets a Team be a single party without the game losing track of the people in it.

## Case File

The accumulating results of the Team's Actions — documents, testimony, research, what the Client has said. Answers *what do we know*, as opposed to the Docket's *what have we done*. One Case File per Team per Simulation; distinct from the Case, which is the authored dispute both Teams share.

## Client

The party a Team represents, present in the game as an avatar with a private range of what they will accept. Reachable only by spending an Action. Authored decision logic, LLM wording.

## Instructor

Runs the Simulations of one Section: forms Teams, pairs them into opposing Sides, sets the pace, plays Events, judges an arbitration, and grades. Not a player — the Instructor sees both Sides' Dockets, Case Files and private Client ranges throughout.

The Instructor's powers over a running Simulation are deliberately few: force-close or extend a Day, play an Event card, waive a Second for one Day. Everything else is set before play or rendered after it.

## Section

An Instructor's class group, and the unit everything configurable hangs off. One Section runs many concurrent Simulations of one Case.

Set per Section: the Case, the number of Days, the deadline schedule, Action Budget size, Client difficulty, the Peer Evaluation flag, and the Event Deck profile. **Par is not** — it is authored in the Case, and a Section that could move it could not be compared to another. Rubric weights are configurable but freeze when the Section's first Simulation starts, because the Rubric is published to students on day one.

## Pairing

Assigning two Teams to the opposing Sides of one Simulation. The Instructor pairs explicitly and assigns the Sides; students choose neither their Team nor their Side. A Team sees its opponent as a Team name — the students on the other Side are not named to it until debrief, and then only at the Instructor's discretion.

## Event

Something that happens *to* the dispute rather than being done by a Team — media attention, a witness changing their story, a court deadline, new evidence surfacing. Shifts what the Clients will accept.

Events are authored per Case as an **Event Deck**, each card carrying its own shift to each Client's valuations and an authored window of Days it may land in. A Simulation's Events are **drawn at its start, never during play**: *which* cards fire is drawn once per Section, so every Team faces the same pressures and Par stays comparable; *when* each fires inside its window is drawn per Simulation, so no two Teams share a timeline. Both Sides of a Simulation share one timeline — it is one dispute.

The draw is seeded, so the Instructor previews and may edit the whole schedule before Day 1, and may play any card manually during the run. Nothing about an Event is decided by a roll the Instructor cannot see in advance.

## Terms

The vocabulary an Offer is built from: money plus a set of authored non-monetary terms — apology, NDA, reinstatement, training, reference letter, policy change. Authored per Case, with a private valuation per Client, so the game can react honestly when a Side offers something other than cash. Free text attaches as a note the Instructor reads; it is not part of the vocabulary.

## Par

The settlement a Case's authors consider well-negotiated **for one Side**. Each Side has its own. It is what Settlement Quality is scored against, with the Client's reservation point as the floor. Par is per-Side and not zero-sum: both Sides can score full marks on the same settlement.

## Rubric

The grade. Four dimensions — settlement quality 40, legal strategy 30, collaboration 20, efficiency 10 — plus a creative-terms bonus of up to 10 above the 100. Published to students in full on day one; **no rubric-derived number is ever visible to a student before the Instructor releases it**. The Instructor sees live provisional scores throughout.

Three dimensions are scored per Team; only collaboration is per-student. Nothing carries a participation floor — a student who does nothing inherits the Team's three dimensions and no more.

## Peer Evaluation

Optional, per-section, at the Instructor's flag. When on, it supplies 6 of collaboration's 20 points; when off, all 20 come from the Docket. Collected once after the Simulation ends, gated so a student sees nothing until they submit: a three-band rating (carried more / pulled even / carried less) and one written line per teammate. Anonymous to teammates, attributed to the Instructor.

## Arbitration

What a Simulation ends in when it runs out of Days without a settlement. **The Instructor is the judge** — a teaching moment, not a computed stalemate. The app assembles the record and drafts a recommendation; the Instructor writes the award and the rationale that actually stand.

Students watch a judgment beat with both Sides present. Nothing about the outcome reaches them until Release.

## Arbitration Packet

What the app hands the Instructor to judge from: both Sides' Pars, both Clients' private ranges, the full Docket, the final Offers on the table, and the gap between them — plus a recommended award and its rationale, drawn from authored factors only. A draft to accept or overwrite, never a verdict.

## Release

The single Instructor action per Simulation that makes outcome, scores and debrief visible to students. Before it, no rubric-derived number and no arbitration result exists for a student. It is what separates the Instructor's live provisional view from the students' silence.

## Debrief Packet

What the app hands the Instructor when a Simulation ends: the outcome, both Clients' private ranges, each Side's Par against what was actually settled, the full Docket, and the provisional scores with their evidence trails. The Instructor runs the debrief; the packet is only what is in the envelope.

Students get a narrower view of their own at Release: the outcome, both Clients' ranges revealed, their own Side's Par against what they settled, and their own Docket. The *other* Side's Docket is a per-Section flag, default off — it is the most instructive thing in the packet and the one that names individual students to their opponents.
