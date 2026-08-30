# Context

Glossary for the BizLaw negotiation simulation. Terms only — no implementation.

## Simulation

One complete run of one Case, from opening to settlement or its failure. Two Teams take opposing Sides. An Instructor starts it, sets its pace, and ends it. Runs over two to three weeks of wall-clock time and contains roughly 8–12 Days.

## Case

The authored dispute a Simulation runs on: the facts, the parties, the documents, and the private positions each Client holds. Data, not code. One Case can back many concurrent Simulations.

A Case is licensed separately from the game that runs it. The game is open; Cases are not — a Case is the authored teaching material, and the engine without one is an empty room.

A Case also authors **reference values** for the things a Section may set — how many Days, how large an Action Budget — because Par is authored against them.

## Case Version

What a Simulation pins. A Case is identified by its name and a version; a **published** version never changes again, so a grading dispute reopened months later reaches the material the Simulation actually ran on. Correcting a published Case means a new version, not an edit.

A **draft** version is the professor's working copy: mutable, invisible to students, and impossible for a Simulation to pin.

## Party

Someone in the dispute the game can put on screen — the two Clients, witnesses, opposing counsel, the judge. Authored per Case, appearance included: with so few garments available, a cast is told apart by hair, colour and glasses, and that is a decision the Case's author makes rather than one drawn at random.

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

**The only scarce resource.** Settlement value is never spendable: a Team cannot buy influence with the money on the table, so no second economy runs beside this one. Retaining outside counsel or an expert is fiction over an ordinary Action — it costs Budget and lead time like anything else, and what it yields is documents.

## Action

One thing a Team spends Action Budget on. Making or revising an Offer is one Action among many; consulting the Client, deposing a witness, requesting documents, researching precedent and managing the press are others. **Consulting the Client costs Budget**, so a Team that never asks negotiates blind.

## Offer

A proposed settlement, with terms. The move that can end the Simulation if the other Side accepts it and the Client will take it.

An Offer is **staged** before it is committed: visible to the whole Team, revisable, costing nothing until it lands.

## Second

A teammate's confirmation, and the only gate inside a Team. An Offer or an Acceptance lands only when a member other than the one who staged it confirms it. Nothing else in the game requires one — the preparation half stays ungated.

A Team whose other members are absent can stage an Offer it cannot commit. That is not a mechanic; it is an Instructor **waiver** of the Second, granted to one Team for one Day and recorded in the Docket as an Instructor action. The Instructor never Seconds on a Team's behalf — Attribution would then name someone who did not take the position.

## Docket

The Team's chronological record of Actions taken: what was spent, which member spent it, and the Day its result lands. Answers *what have we done and what is coming*. Visible to the whole Team, naming who acted; it carries no per-member totals or contribution scores. Seen forward it is the Team's calendar — there is no separate one.

## Attribution

The record of which member took an Action. Attached to every spend. It is what lets a Team be a single party without the game losing track of the people in it.

## Case File

The accumulating results of the Team's Actions — documents, testimony, research, what the Client has said. Answers *what do we know*, as opposed to the Docket's *what have we done*. One Case File per Team per Simulation; distinct from the Case, which is the authored dispute both Teams share.

Everything in it is a document. Some documents also carry an **Exhibit** — the Case File is a folder that happens to hold a few playable things, not a hand.

It also holds every document the other Side has served, flagged as served rather than found. Those arrive without an Exhibit property: service gives a Team knowledge, never ammunition.

## Exhibit

A Case File document a Team can put in front of the other Side to move a Client's valuation. Not a separate kind of object: an Exhibit is an authored **property** some documents carry and most do not, so preparation yields one thing, not two.

An Exhibit carries a target, a sign, a shift, and the **Terms** it bears on. **Favorable** Exhibits are played and move the *opposing* Client. **Unfavorable** ones are not playable at all — they land the moment they are discovered and move *your own* Client toward realism, lowering what they will hold out for. Deposing a witness who hurts you still teaches you something worth knowing.

Playing one **rides a staged Offer** and costs Action Budget; it cannot be played alone, and any number may ride one Offer. It moves the Client only when the Offer touches the Terms it bears on — a document arguing for reinstatement is worth nothing attached to a cash-only Offer. Shifts stack additively against an authored bound on how far a Client may move across one Simulation.

The Exhibit is spent when played; the document is not, and stays in the Case File as what the Team knows. The shift lands the moment the Offer commits, and the document reaches the other Side at that same instant. The receiving Team is **served the document and never its effect** — playing an Exhibit is serving it.

**A served Exhibit cannot be answered.** There is no rebuttal: the ratchet leaves nothing to undo, and a served document carries no Exhibit property for its recipient. What service opens is an informational beat — visible and free, its direction legible from reading the document, its weight only ever a Reaction Band bought with an Action. The strategic response is ordinary play: they softened your Client, so go soften theirs.

An Exhibit played after its target's bound is exhausted is still spent, and its shift is **clipped** to whatever travel remains. It scores regardless — a good argument put to a Client who has already come around is still a good argument, and a Team cannot see the bound it would be punished for missing.

## Provenance

How a document came to be in a Team's hands. Three are authored in the Case — in both Sides' hands at the open, in one Side's hands at the open, or waiting behind an Action to be discovered. The fourth, **served**, is never authored: it is what happens when the other Side plays an Exhibit.

Provenance is what makes *doors visible, contents hidden* checkable — every discoverable document must sit behind some Action, and nothing a Team starts with can also be something it finds.

## Firm

The room a Team prepares in: its own conference table, its own Client, no opponent. The Case File lies on it as papers and the Action Board sits beside them.

One of the two rooms a Day moves between, freely and in either direction. The door is never the gate — the Second is.

## Boardroom

The room the exchange happens in, and the only place an Offer can commit. Seats three: the Team's own Client in the foreground, the opposing Client and opposing counsel across a conference table.

**Only the Team's own Client is expressive.** The figures across the table are presence, not a read — a face that reacted honestly to a committed Offer would hand over the opposing Client's reservation point for free, which is the read a Consult is charged for. Their being seated is fiction, never a claim the other Team is online.

## Terms Board

Where the shape of the deal is visible: each Term as a track carrying the Team's own position, the other Side's **last committed** Offer, and the Team's own Client's stated aspiration. Reachable from either room, because deliberation is preparation work even though the commit is not.

It never shows Par. Par is what the grade is measured against, and no rubric-derived number reaches a student before Release. The Client's aspiration is the in-fiction stand-in, and it gives nothing away, because an aspiration does not move.

## Action Board

The menu of what a Team could do this Day, each Action with its cost and its lead time. *What we could do* — opposite the Case File's *what we know* and the Docket's *what we have done*.

## Close-up

One figure's face, scaled up over the dimmed room. **Emphasis, never the sole carrier**: whatever a Close-up says also lands in the Docket or the Case File, so skipping one costs a Team nothing.

The game cuts on authored beats only — a Reaction Band change, and an Offer accepted or rejected — at most one per commit, and always the Team's own Client. A student may push in on any figure at any time, free. An Event, an arbitration award and a served document get no cut; they are documents, and reading them is the beat.

## Morning Briefing

What a Day opens with, over the Firm's table: the Actions that have just landed and any documents the other Side served. The same object a returning absent teammate is given, widened.

## Client

The party a Team represents, present in the game as an avatar with a private range of what they will accept. Reachable only by spending an Action. Authored decision logic, LLM wording.

What moves during a Simulation is the Client's **reservation point** — the worst settlement they will take. Their aspiration does not move: they still want what they wanted, so a Client's stated demands never reveal that they have softened.

Player-caused movement is a **ratchet**. Exhibits and discoveries only ever move a reservation point toward settleability, never back out toward holding firm, and the total inward travel across one Simulation is bounded per Client by the Case. Both Sides draw on that one bound — the opposing Team's favorable Exhibits and the Team's own unfavorable discoveries spend the same budget. Only an Event can move a reservation point back out.

The bound is the one thing about a Client authored as money; every shift against it — an Exhibit played, a bad discovery, an Event — is a **fraction** of it. So an Exhibit is worth the same share of a Client's travel whether the Section made that Client easy or hard.

## Reaction Band

What a Client says about where they stand, and the only read a Team ever gets on how far their Client has moved. Authored per Client as an ordered set of bands — firm, wavering, ready — keyed to the cumulative fraction of the bound consumed, never to any single Exhibit.

Reachable only by consulting the Client, so knowing where you stand costs Action Budget. A band is qualitative: no number, no reservation point, no size of any shift. The band is the authored decision; the wording is generated.

## Instructor

Runs the Simulations of one Section: forms Teams, pairs them into opposing Sides, sets the pace, plays Events, judges an arbitration, and grades. Not a player — the Instructor sees both Sides' Dockets, Case Files and private Client ranges throughout.

The Instructor's powers over a running Simulation are deliberately few: force-close or extend a Day, play an Event card, waive a Second for one Day. Everything else is set before play or rendered after it.

## Section

An Instructor's class group, and the unit everything configurable hangs off. One Section runs many concurrent Simulations of one Case.

Set per Section: the Case, the number of Days, the deadline schedule, Action Budget size, Client difficulty, the Peer Evaluation flag, and the Event Deck Profile. **Par is not** — it is authored in the Case, and a Section that could move it could not be compared to another. Rubric weights are configurable but freeze when the Section's first Simulation starts, because the Rubric is published to students on day one.

Day count and Action Budget arrive with the Case's reference values, and a Section that changes either is marked as no longer comparable to one that did not — Par assumed those numbers. **Client difficulty** makes an authored Client harder or easier to satisfy; it never swaps in a different Client, so a Case authors one of each, not three.

## Pairing

Assigning two Teams to the opposing Sides of one Simulation. The Instructor pairs explicitly and assigns the Sides; students choose neither their Team nor their Side. A Team sees its opponent as a Team name — the students on the other Side are not named to it until debrief, and then only at the Instructor's discretion.

## Event

Something that happens *to* the dispute rather than being done by a Team — media attention, a witness changing their story, a court deadline, new evidence surfacing. Shifts what the Clients will accept.

Events are authored per Case as an **Event Deck**, each card carrying its own shift to each Client's valuations and an authored window of Days it may land in. A Simulation's Events are **drawn at its start, never during play**: *which* cards fire is drawn once per Section, so every Team faces the same pressures and Par stays comparable; *when* each fires inside its window is drawn per Simulation, so no two Teams share a timeline. Both Sides of a Simulation share one timeline — it is one dispute.

An Event's shift carries a **direction**, and Events are the only thing exempt from the Client ratchet — the only force that can move a reservation point back out toward holding firm. An outward shift restores bound rather than consuming it, so a Simulation cannot run out of travel. This is what lets a media firestorm harden a Side's resolve while the tug-of-war stays out of players' hands entirely.

The draw is seeded, so the Instructor previews and may edit the whole schedule before Day 1, and may play any card manually during the run. Nothing about an Event is decided by a roll the Instructor cannot see in advance.

## Event Deck Profile

A named subset of a Case's Event Deck — quiet, normal, turbulent — that an Instructor chooses for a Section. Authored, because pacing is a judgement about which pressures belong in one dispute together; a Section choosing a number of cards instead could deal a combination the Case's author never thought playable.

## Terms

The vocabulary an Offer is built from: money plus a set of authored non-monetary terms — apology, NDA, reinstatement, training, reference letter, policy change. Authored per Case, with a private valuation per Client, so the game can react honestly when a Side offers something other than cash. Free text attaches as a note the Instructor reads; it is not part of the vocabulary.

Terms are **atomic**. A public apology and a private one are two Terms, never one Term with a setting — a Client values each Term at a single amount, which is what lets an Offer be worth one number to them.

Cost allocation is a Term like any other. Who pays whose fees, or how a mediator is paid for, is something the Sides negotiate rather than something the engine deducts — which keeps *winning bigger and netting less* inside the Offer's value to the Client, and leaves Par with no gross-or-net distinction to draw.

## Par

The settlement value a Case's authors consider well-negotiated **for one Side** — a single number, in the same money the Offer is worth to a Client. Each Side has its own. It is what Settlement Quality is scored against, with the Client's reservation point as the floor. Par is per-Side and not zero-sum: both Sides can score full marks on the same settlement.

Par **assumes the case was worked** — it is authored as what a Side that used its Exhibits should get, so a Team that plays none falls short of it. Par never moves with what a Team actually did; a Par that adapted would grade each Team against its own choices and hide poor play. It also assumes the Case's reference Day count and Action Budget, which is why a Section that changes those loses comparability.

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
