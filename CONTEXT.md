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

Someone the game **seats**. Exactly four per Case: one Client and one counsel for each Side. Authored per Case, appearance included: with so few garments available, a cast is told apart by hair, colour and glasses, and that is a decision the Case's author makes rather than one drawn at random.

Not everyone in the dispute is a Party. Witnesses, experts, reporters and the judge are never seated and never portrayed; they exist as prose inside the documents that mention them. Nothing in the engine would read a record for them — an Exhibit targets a Client, an Action yields documents, and only a Client carries a persona, a brief, Reaction Bands and a reservation point.

Each counsel is only ever seen by the *opposing* Side. A Team never looks at its own counsel, because the students are the counsel.

## Side

Plaintiff or defendant. A Side is a position in the dispute, not a group of people — the Team is the people. The two Sides are deliberately **asymmetric**: they have different action menus, because building pressure and containing exposure are different jobs.

A position *in a dispute* exists per dispute, so a Side belongs to one Simulation and there are exactly two. It is the thing everything a Team accumulates hangs off: the Action Budget, the Docket, the Case File, the staged Offer, and the Client it represents. A Team is paired to a Side; the pairing is what joins the people to the position.

## Team

The small group of students playing one Side. Three to five, and **flat** — no lead counsel, no researcher, no liaison. Every member has the same standing and the same Action menu; specialisation is a strategy a Team may choose, never a permission the game grants.

A Team acts as a single negotiating party: one shared state, one Action Budget, one set of committed Actions. Each student sees that state through their own view, so a Team sitting together and a Team working apart are playing the same Day.

## Day

**The unit of play.** A Day opens, the Team spends its Action Budget, and the Day closes. A Day is a unit of the *Simulation*, not of wall-clock time: a Team sitting together in class may burn a Day in twenty minutes, a Team working apart may take three evenings over it. Both are the same Day.

**Committing the Day and committing an Offer are different acts.** A Side commits its Day by declaring itself finished with it; committing an Offer is a Boardroom act, at most one per Side per Day, and it implies the Day commit. The reverse does not follow — a Side that spent its whole Budget on preparation and made no Offer has still finished its Day. A Day closes when both Sides have committed it, or when the Instructor's deadline fires.

The Simulation's Days all exist before the first one is played, because the Case authors an ordered calendar with in-fiction dates. That is what lets an Action taken today name the Day its result lands on, and what lets the Instructor preview and edit the whole Event schedule before Day 1.

Not to be confused with the old app's *round*, which was a submission box holding one number per Side.

## Action Budget

What a Team has to spend within one Day. The scarce resource that makes preparation compete with negotiation — the tension the course is actually about.

**The only scarce resource.** Settlement value is never spendable: a Team cannot buy influence with the money on the table, so no second economy runs beside this one. Retaining outside counsel or an expert is fiction over an ordinary Action — it costs Budget and lead time like anything else, and what it yields is documents.

The Budget arrives in two halves each Day and **neither half carries to the next Day**. The **preparation half** is ungated and buys everything that is not an Offer. The **exchange half** is an absolute number of points, not a fraction of the Budget — it is authored as a count, and the reference Case authors **two**, which buys exactly one Offer and one Exhibit riding it. That number is the whole brake on the game's one degenerate strategy: because the halves do not carry, the exchange half caps Exhibits-per-Offer and the number of Offers caps total plays, so a Team that hoards its Exhibits physically cannot dump them. Below two points nothing can be played at all and the design stops discriminating; at three the dump becomes affordable again.

Expressing the exchange half as a *fraction* is a mistake worth naming, because it silently couples the brake to the Budget: at a fifth of a ten-point Budget the brake is correct, and the same fifth of a nine-point Budget falls under two points and the game collapses. The Case authors the pool; the preparation half is what is left.

**The Budget is not the same size every Day.** Past a knee at three fifths of the Simulation the preparation allowance collapses to roughly the price of a Consult and the exchange half widens by one point — the reference Case authors 2 and 3 against a flat 8 and 2. This is the shape of the Day changing, not a reward: measured, the closing Days spend their exchange half to within a fifth of a point while the *entire* preparation allowance expires, because discovery bought after the lead times can no longer land. A flat Budget therefore hands a Team three or four Days on which the ungated half buys nothing at all.

Widening the exchange half **only past the knee** is what makes this safe. Widening it everywhere would flatten the preparation-against-negotiation tension for the whole Simulation and costs a case-working Team seven points of Par rate; past the knee it costs nothing, because the number of Days left is what caps total plays and four Days of Offers cannot absorb a hoard.

**Three is not a cliff, and what bounds it is the case-worker rather than the hoarder.** The dump opens *smoothly* with the closing exchange half — Exhibits a hoarder actually plays run 0.07 flat, 0.14 at three, 0.19 at four, 0.31 at six — so there is no threshold above which it suddenly becomes affordable. What changes sharply is the price to a Team playing properly: a case-worker holds its Par rate at three (0.949 against a flat 0.960) and starts paying for the width at four (0.914) and five (0.881). Three is authored because it is the last point that is free, not because four is a wall. A Team's own Par rate is the binding constraint on this number; the hoarder's is not, and the hoarder's *Par rate* in particular is a poor read on the dump, because it moves with how much firepower the same knob hands its opponent.

**Roughly an eighth of the Budget still expires unspent, and that is the design paying for itself** — most of it now in the exchange half on Days where a Side makes no Offer. Every attempt to reclaim the rest costs more than it returns. A Team is shown what it has left **today** and never a cumulative unspent total: the expiry is a structural cost of the brake, so a running waste figure would grade a Team on a number the design requires of it.

**No Action was added to fill the closing Days, and one was measured and rejected.** The surviving candidate was a preparation-half Action that multiplied the shift of an Exhibit a Team already held. It fails three ways at once. Its multiplier has no gradient — 1.1× and 8× give the same result, because a shift is clipped at the Client's remaining bound and Settlement Quality is capped at Par, so the ratchet's own bound is the ceiling and multiplying a clipped number changes nothing. Where it has a sign at all the sign is negative: a case-worker that buys it loses rubric points for spending. And an Action purchasable only while *holding* an unplayed Exhibit pays for hoarding by construction, which is the one strategy the exchange half exists to price out. A Day is better left quiet than filled with a button that reads as a choice and is not one.

## Action

One thing a Team spends Action Budget on. Making or revising an Offer is one Action among many; consulting the Client, deposing a witness, requesting documents, researching precedent and managing the press are others. **Consulting the Client costs Budget**, so a Team that never asks negotiates blind.

A spend is irreversible and, unlike an Offer, ungated by a Second, so **every spend confirms** — naming the cost, the Budget remaining today, and the Day the result lands. Uniformly, never only a first one: there is no per-student state to know whose first it is, and a per-Team first would vanish for the teammate who never saw it. It is the surface where lead time is explained at the moment it bites.

## Offer

A proposed settlement, with terms. The move that can end the Simulation if the other Side accepts it and the Client will take it.

An Offer is **staged** before it is committed: visible to the whole Team, revisable, costing nothing until it lands.

An Offer is worth **two numbers, one per Client**, because each Client values the Terms privately. The Sides negotiate a single instrument and are graded on different figures: Settlement Quality reads each Side's own Client's valuation of the Offer against that Side's Par. The two figures coincide only where an Offer is **pure cash** — money is the one Term worth its face to both Clients. So an agreement struck outside the game can fix the instrument but not the score, unless it is written in cash alone.

## Second

A teammate's confirmation, and the only gate inside a Team. An Offer or an Acceptance lands only when a member other than the one who staged it confirms it. Nothing else in the game requires one — the preparation half stays ungated.

The Second is never explained in advance. A student who stages an Offer holds a commit control that is **present and disabled, naming the teammates who can second it**, and the staging lands in the Docket with Attribution so it surfaces in a teammate's next Morning Briefing. A dead control in the hand teaches the rule that the door is never the gate; fixed copy elsewhere would not.

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

It seats one figure. Teammates are not avatars, and nothing a Team does seats anyone else — retaining outside counsel or an expert yields a report, not a body. The framing is first-person from the Team's own side of the table.

One of the two rooms a Day moves between, freely and in either direction. The door is never the gate — the Second is.

## Boardroom

The room the exchange happens in, and the only place an Offer can commit. Seats three: the Team's own Client in the foreground, the opposing Client and opposing counsel across a conference table.

Three is the engine's number, and the cast never changes. The seats are **roles**, not a count — mine, theirs, their counsel — and there is no fourth role for anyone to fill. Nobody arrives mid-Simulation and nobody leaves: since only a Client ever speaks, an arriving Party would change the picture and nothing else.

**Only the Team's own Client is expressive.** The figures across the table are presence, not a read — a face that reacted honestly to a committed Offer would hand over the opposing Client's reservation point for free, which is the read a Consult is charged for. Their expression is authored on the Party and fixed for the whole Simulation, never derived from their Reaction Band. Their being seated is fiction, never a claim the other Team is online.

## Terms Board

Where the shape of the deal is visible: each Term as a track carrying the Team's own position, the other Side's **last committed** Offer, and the Team's own Client's stated aspiration. Reachable from either room, because deliberation is preparation work even though the commit is not.

It never shows Par. Par is what the grade is measured against, and no rubric-derived number reaches a student before Release. The Client's aspiration is the in-fiction stand-in, and it gives nothing away, because an aspiration does not move.

## Action Board

The menu of what a Team could do this Day, each Action with its cost and its lead time. *What we could do* — opposite the Case File's *what we know* and the Docket's *what we have done*.

## Close-up

One figure's face, scaled up over the dimmed room. **Emphasis, never the sole carrier**: whatever a Close-up says also lands in the Docket or the Case File, so skipping one costs a Team nothing.

The game cuts only where a Client has something to say — a Consult, and settlement — at most one per commit, and always the Team's own Client. A cut is never a free read: a Reaction Band that moves is shown at the next Consult, not the moment it moves. A student may push in on any figure at any time, free. An Event, an arbitration award and a served document get no cut; they are documents, and reading them is the beat.

## Morning Briefing

What a Day opens with, over the Firm's table: the Actions that have just landed and any documents the other Side served. The same object a returning absent teammate is given, widened.

It carries a further section, **what you start with** — the documents in hand at the open, drawn from Provenance, beside the Client's opening statement, the calendar and the Rubric. On Day 1 that is the only non-empty section, because nothing has landed and nothing has been served yet; on later Days it is what a returning teammate is caught up on. Every section is composed by the engine from objects the Case already authors, so a briefing is never authored per Case.

It is also where the two-room grammar is **named**, in one line of fixed copy: prepare in the Firm, deal in the Boardroom, move between them freely, the Day ends when both Sides commit. A room is never empty, so no room's own state can carry it.

## Onboarding

How a first-timer learns to operate the machine. It owns *operating the machine* and nothing else — what a good settlement looks like is the course's job, answered by the professor, the published Rubric and the Client's opening statement.

**It has no object of its own.** No first-run pass, no practice Case before the graded run, no Section knob, and no per-student progress state — a "this student has seen it" flag is a status column with no ledger event behind it, and the runtime schema has none. **The empty state is the tutorial**: an empty Docket says what a Docket would hold, a full Action Board says what an Action costs and when it lands, the Case File holds only what you started with. The Morning Briefing carries the Day, and a disabled control carries the Second.

Because there is no per-student state, the surface cannot open up over Days. Disclosure derives from *Team* state only, and almost nothing qualifies: both rooms, the toggle, the three record surfaces, the Terms Board and the whole Action Board with every cost and lead time are present from Day 1 — hiding what an Action costs makes the Budget unplannable, and planning the Budget is the lesson. Only the Exhibit affordances gate, appearing when the Case File first holds a document carrying one. The rule: gate a control only where it would otherwise be **inert**, so it teaches itself the moment it becomes real.

**Learning is not subsidised.** Day 1 scores like any other Day, with no efficiency carve-out — a Day where mistakes are free teaches that Budget is not scarce, which is the one thing the Action Budget exists to prevent. A fraction of the Budget already expires unspent, so the fumble is cheap without an exemption.

An Instructor demoing from a demo Section is a supported **accelerator, never a dependency**: a student who missed the demo is the absent teammate the Morning Briefing already has to catch up.

## Client

The party a Team represents, present in the game as an avatar with a private range of what they will accept. Reachable only by spending an Action. Authored decision logic, LLM wording.

What moves during a Simulation is the Client's **reservation point** — what the Case considers the worst settlement worth taking. It is **a target for shifts and nothing else: never a veto, and not the scoring floor either**. A Team may accept any Offer, and a deal beneath the reservation point simply scores badly against Par. A Client who could refuse would hand over that number to any Team willing to probe for it; and a Client whose live number set the grading scale would hand one Side's scale to the other Side's diligence, because the opposing Team's Exhibits are what move it. The floor Settlement Quality ramps from is authored and immobile — see *Par*.

Their aspiration does not move: they still want what they wanted, so a Client's stated demands never reveal that they have softened.

Player-caused movement is a **ratchet**. Exhibits and discoveries only ever move a reservation point toward settleability, never back out toward holding firm, and the total inward travel across one Simulation is bounded per Client by the Case. Both Sides draw on that one bound — the opposing Team's favorable Exhibits and the Team's own unfavorable discoveries spend the same budget. Only an Event can move a reservation point back out.

The bound is the one thing about a Client authored as money; every shift against it — an Exhibit played, a bad discovery, an Event — is a **fraction** of it. So an Exhibit is worth the same share of a Client's travel whether the Section made that Client easy or hard.

## Reaction Band

What a Client says about where they stand, and the only read a Team ever gets on how far their Client has moved. Authored per Client as an ordered set of bands keyed to the cumulative fraction of the bound consumed, never to any single Exhibit.

**There are two — *firm* and *ready* — and the edge is authored late, around four fifths of the bound.** Both halves of that are measured rather than chosen. An early edge is a Client crying wolf: the Team reacts while nothing has really happened, and pays for it. And a third band earns nothing a second does not, while a fourth is strictly worse than three at every threshold tried — so the inventory question never becomes a trade.

Reachable only by consulting the Client, so knowing where you stand costs Action Budget. A band is qualitative: no number, no reservation point, no size of any shift. The band is the authored decision; the wording is generated.

**A band is a bucket, so it is imprecise near the ends by construction** — a Client four fifths of the way through its bound and one that has exhausted it read the same. Nothing is owed to that: a clipped Exhibit still scores, so a Team playing into an exhausted bound gets a true signal, a useless one, and full credit alike.

**What a Consult is worth is set by the Event Deck, not by the thresholds.** A Team can see every blow land — service is visible and its direction legible — so what it lacks is the *size*, and its own running count drifts rather than breaking. An Event is the one thing that moves a Client back **outward**, which is the single moment a Team's picture is not merely stale but pointing the wrong way. So the Consult is an instrument used rarely and on an occasion, never a purchase made on a timetable, and it is worth **nothing at all in a Section whose Event Deck Profile draws no Events**.

That is also why it is cheap. A Consult costs **1**: a Team's own reservation point is a target for shifts and nothing else, so no decision the Rubric rewards actually runs on it, and a Team that never consults is not thereby playing badly. Priced any higher, consulting is a tax on the Teams that stay in character. Priced this low, consulting on every Day is still self-defeating — the band's imprecision is what stops a Team buying its way to the number, and the Consult's own price is what stops it trying.

## Dialogue Node

A situation in which a Client speaks, and the unit generated dialogue is stored against. **The Client is the only Party that ever speaks.** Opposing counsel, the opposing Client, witnesses and the judge are presence or documents — an opposing figure with honest words would give away the reservation point a Consult is charged for, and the counsel across the table stands in for the opposing Team, whose words are the students' own.

The engine defines the node **kinds**; the Case's own data multiplies out the instances, so the inventory is a closed cross-product known before it is generated. A node is **atomic** — one whole utterance, never slots assembled at runtime — so the bytes a professor reviews are the bytes a student reads. Each carries several variants, chosen by the Simulation seed *and* how many times the node has already been spoken, so a Client consulted on five Days does not repeat itself.

A line is generated only where a Party speaks about something the engine computed. Anything that exists as an object in the dispute — an Event's news story, a deposition transcript, an arbitration award, a served document, the Client's opening statement of what they want — is authored prose and never reaches the model. Anything describing the machine rather than the dispute — the Morning Briefing, the Action Board, the Docket — is fixed interface copy.

Generation is given the Client's persona, the Reaction Band and an authored per-Client brief, and **never a number**: no reservation point, no bound, no Par, no size of any shift. A figure a line cannot see is a figure a line cannot leak, and editing Par therefore invalidates no dialogue.

The avatar's expression is derived from the Reaction Band by engine rule rather than authored on the node, so a Client's face cannot change between two variants that mean the same thing. The rule reaches **the Team's own Client only**: the opposing Client's expression is authored and fixed, or the face would give away what a Consult is charged for.

A Case that does not supply every node and every variant does not import.

## Student Prose

Everything students write inside a Simulation: the note attached to an Offer, the deliberation threads anchored to a staged Offer, and the Peer Evaluation's written line per teammate. All of it is Team-internal or Instructor-bound — nothing a student writes ever crosses to the opposing Side.

**It stays in the app, and then it stops existing.** Prose is the `:prose` tier under Retention: destroyed 30 days after the Section's end date, ahead of the graded skeleton it sits inside. The Peer Evaluation line goes with it and the score it produced survives, so a late collaboration appeal is answered from the number rather than the sentence. The Offer note goes with it too — the Rubric scores legal strategy from the Docket precisely so that text is never grading evidence, which leaves the note no evidentiary job to protect.

**No model ever reads it.** The LLM writes Client lines and reads nothing a student typed: no digest of deliberation for the Instructor, no characterisation of what a Team argued, no safety pass before a teammate sees a message. The load-bearing reason is consent, not architecture — student prose is an educational record this product has no agreement to send to a vendor, and the `zdr: true` pinning in ADR 0001 protects Case content as product IP, which is a promise about the professor's work rather than the students'. The architectural reason corroborates: student text does not exist at case-authoring time, so any read would be a runtime call into a web tier that holds no API key. It is the weaker of the two, because a background job satisfies it.

A digest would also be the objection the Rubric already ruled on. Legal strategy scores from the Docket rather than from keyword-matched text; a model-written summary the Instructor grades from is that objection wearing a better coat, and one they do not grade from is a summary of threads capped by one commit per Side per Day.

The invariant reaches past the model to any processor that receives data incidentally — error tracking, analytics, log aggregation — as a rule about the payload rather than a ban on the tools: those may run, with student prose scrubbed from what leaves. The host is a different case; data on the application's own volume is tenancy, not disclosure. No consent flow is built, because the invariant is what removes the need for one.

What replaces a digest is structure the design already has. Deliberation is anchored to a staged Offer rather than being a general chat, so a thread renders where its Offer sits in the Docket, attributed and in Day order — the Instructor reads prose in place, at full fidelity, and it is inside their live visibility alongside the Dockets and Case Files. Nothing catches abusive prose except the person already reading it, which is the answer in any graded group work.

Enforcement matches the Case import gate rather than resting on review: the LLM client is reachable only from the generation rake task's path and is never autoloaded into the web tier, asserted by a spec, so a runtime read fails to load.

## Retention

Every table declares a tier — `:prose`, `:skeleton` or `:authored` — and a spec fails on any table that declares none. The scheduled purge reads the declaration rather than a maintained list, so a new prose-bearing table added without a tier breaks the build instead of quietly retaining student writing forever.

A record is often prose and skeleton at once: a deliberation message is writing on the `:prose` clock, but who wrote it and on which Day belong to the graded shape and outlive it by eleven months. So a table declares its tier **and names which of its columns are the prose**, and the earlier purge empties those columns where they sit. The writing is genuinely destroyed; what survives is the row that becomes the tombstone.

`:prose` is Student Prose. `:skeleton` is the graded shape: Docket, committed Offers, outcome, scores, revealed ranges, Attribution, and the generated Client lines with their utterance index. `:authored` is Case rows and their pinned Case Versions — the professor's work, never a student record, never purged.

**Prose is destroyed 30 days after the Section's end date; the skeleton one year after it.** Both are hard deletes, because a `deleted_at` row still holding the prose is not a purge and a soft-deleted skeleton keeps every student name forever. The clocks are short because the app is not the grade book: the grade of record leaves through the Instructor into the school's records at Release, so what the run owes afterwards is evidence for a dispute, not a transcript. Nothing survives a Section purge but the `:authored` tier — the Section shell and its roster go with the run.

**The anchor is a date, not an event.** A Section is given an end date when it is created, because a term knows its ending before it starts. An explicit *close the Section* act never gets performed, and deriving the end from the last Release never fires for a Section holding one stalled Simulation. Release therefore has no retention effect at all; it gates visibility and nothing else. The date never force-closes play, the Instructor may move it, moving it later after a purge revives nothing, and the Section board warns as a purge approaches — a warning rather than a block, since a block would reintroduce the failure the date was chosen to avoid.

**A purged pointer renders as a tombstone, never as silence** — *3 messages, purged*, with attribution and Day intact. Silence would read as *this student wrote nothing*, the most damaging wrong inference available, on the one dimension graded per student.

Two things are refused deliberately. There is **no export** ahead of the prose purge: it would be a bulk export of student writing relocated to a laptop, uncontrolled and permanent, and it would make the policy decorative. And there is **no per-student erasure** — Attribution sits on every spend, so removing one student guts their Team's Docket and damages their teammates' record. The answer to a withdrawal is the Section clock. A named gap, not an oversight.

## Instructor

Runs the Simulations of one Section: forms Teams, pairs them into opposing Sides, sets the pace, plays Events, judges an arbitration, and grades. Not a player — the Instructor sees both Sides' Dockets, Case Files, deliberation threads and private Client ranges throughout.

The Instructor's powers over a running Simulation are deliberately few: force-close or extend a Day, play an Event card, waive a Second for one Day. Everything else is set before play or rendered after it.

## Section

An Instructor's class group, and the unit everything configurable hangs off. One Section runs many concurrent Simulations of one Case.

Set per Section: the Case, the number of Days, the deadline schedule, Action Budget size, Client difficulty, the Peer Evaluation flag, the Event Deck Profile, and an **end date**, which is the anchor every Retention clock is measured from. **Par is not** — it is authored in the Case, and a Section that could move it could not be compared to another. Rubric weights are configurable but freeze when the Section's first Simulation starts, because the Rubric is published to students on day one.

Day count and Action Budget arrive with the Case's reference values, and a Section that changes either is marked as no longer comparable to one that did not — Par assumed those numbers. **Client difficulty** makes an authored Client harder or easier to satisfy; it never swaps in a different Client, so a Case authors one of each, not three.

A Section belongs to an Organization, and an Instructor is an Instructor *of a Section* rather than by standing — the same person may teach one Section and appear nowhere in another.

**Onboarding is not a Section knob.** Every knob changes the simulation; onboarding changes none of them, and a knob implies an off position that would leave a first-timer with no teaching.

A **demo Section** is an ordinary Section of the same Case, seeded, with no real students in it — what an Instructor teaches a room of first-timers from. Nothing in the engine knows it is a demo: no flag, no mode, no exclusion. It is created and re-created by a rake task alongside `case:import`, seeded from a **recorded playthrough replayed as ledger events** rather than hand-written fixtures, so it cannot drift from the runtime schema silently and a Section aged out under Retention's clocks is re-seeded rather than preserved. The same artifact is the development fixture, which is what earns building it. It sits on whatever Day shows the record surfaces full; projecting a live Simulation could only ever show an empty Docket.

## Organization

The institution a Section belongs to, and the boundary no data crosses. Everything a person can reach — their Sections, Teams, Simulations and Sides — descends from one Organization, and a document, a Docket or a score never travels between two.

Cases sit outside it. A Case is the authored teaching material, shared by every Organization licensed to run it, and belongs to none of them.

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

The settlement value a Case's authors consider well-negotiated **for one Side** — a single number, in the same money the Offer is worth to a Client. Each Side has its own. It is what Settlement Quality is scored against. Par is per-Side and not zero-sum: both Sides can score full marks on the same settlement.

Settlement Quality's forty points ramp from a **floor a quarter of the bound short of Par**, full marks at Par and beyond, nothing at or below the floor. The floor is derived from the two numbers the Case already authors — it adds no third money denominator — and it is **immobile**, which is the point of it: the Client's live reservation point is moved by the *opposing* Team's Exhibits, so ramping from it would let one Side's grading scale be set by how hard its opponent worked. A quarter of the bound is what makes the ramp discriminate: a wider floor hands a Team that never worked the case most of the forty points for turning up, and no ramp at all puts forty points on a single threshold.

Par **assumes the case was worked** — it is authored as what a Side that used its Exhibits should get, so a Team that plays none falls short of it. Par never moves with what a Team actually did; a Par that adapted would grade each Team against its own choices and hide poor play. It also assumes the Case's reference Day count and Action Budget, which is why a Section that changes those loses comparability.

## Rubric

The grade. Four dimensions — settlement quality 40, legal strategy 30, collaboration 20, efficiency 10 — plus a creative-terms bonus of up to 10 above the 100. Published to students in full on day one; **no rubric-derived number is ever visible to a student before the Instructor releases it**. The Instructor sees live provisional scores throughout.

Three dimensions are scored per Team; only collaboration is per-student. Nothing carries a participation floor — a student who does nothing inherits the Team's three dimensions and no more.

## Peer Evaluation

Optional, per-section, at the Instructor's flag. When on, it supplies 6 of collaboration's 20 points; when off, all 20 come from the Docket. Collected once after the Simulation ends, gated so a student sees nothing until they submit: a three-band rating (carried more / pulled even / carried less) and one written line per teammate. Anonymous to teammates, attributed to the Instructor.

## Arbitration

What a Simulation ends in when it runs out of Days without a settlement. **The Instructor is the judge** — a teaching moment, not a computed stalemate. The app assembles the record and drafts a recommendation; the Instructor writes the award and the rationale that actually stand.

The draft is kept beside what the Instructor wrote rather than being overwritten by it, so a record reopened later shows which of the two the students were given.

Students watch a judgment beat with both Sides present: the award arrives as a document in the Boardroom, over the standing three. There is no judge at the table — the judge is the Instructor, who was never a Party — and the Client says nothing, because the only honest thing it could speak to is an award invisible until Release. Nothing about the outcome reaches them until Release.

## Arbitration Packet

What the app hands the Instructor to judge from: both Sides' Pars, both Clients' private ranges, the full Docket, the final Offers on the table, and the gap between them — plus a recommended award and its rationale, drawn from authored factors only. A draft to accept or overwrite, never a verdict.

**The drafted award is final-offer: it is one of the two final Offers, whichever sits closer to the merits, and never a split between them.** A draft that splits the difference pays intransigence — a Side that never moves off its opening demand drags the midpoint with it, and since a Client's reservation point is private, refusing to negotiate becomes the strongest play available. Choosing between the two positions instead makes the unreasonable one the losing one. The Instructor still overwrites whatever they like; this is only what the app proposes.

## Release

The single Instructor action per Simulation that makes outcome, scores and debrief visible to students. Before it, no rubric-derived number and no arbitration result exists for a student. It is what separates the Instructor's live provisional view from the students' silence.

**Release is also what fixes the scores.** Up to that moment a provisional score is recomputed from the record every time it is looked at, so an Instructor's adjustment shows up immediately. At Release each score is written down for good, alongside the weights and the Par it was measured against — a grade queried a year later is answered from what the student was actually shown, not by recomputing it against rules that have since changed.

## Debrief Packet

What the app hands the Instructor when a Simulation ends: the outcome, both Clients' private ranges, each Side's Par against what was actually settled, the full Docket, and the provisional scores with their evidence trails. The Instructor runs the debrief; the packet is only what is in the envelope.

Student prose does not travel in it. Deliberation threads and Offer notes stay in the application, and the packet points into the run rather than carrying them — which is what keeps it from being a bulk export of student writing. Those pointers resolve to nothing once the prose is purged, and render as a tombstone rather than as an empty thread.

Students get a narrower view of their own at Release: the outcome, both Clients' ranges revealed, their own Side's Par against what they settled, and their own Docket. The *other* Side's Docket is a per-Section flag, default off — it is the most instructive thing in the packet and the one that names individual students to their opponents.
