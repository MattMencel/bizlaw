# The voice

Decided in [What voice do we write in?](https://github.com/MattMencel/bizlaw/issues/388), 2026-09-22. It builds on the [diagnostic audit](https://github.com/MattMencel/bizlaw/blob/research/copy-audit/docs/research/copy-audit.md). Three voices were prototyped (plain app voice, clerk's note, senior associate), and this is the senior associate. The prototype is on the branch [`prototype/voice`](https://github.com/MattMencel/bizlaw/tree/prototype/voice).

This covers everything a player reads: interface copy and the demo's fiction. The reader is an undergraduate in a business law course who skims. The voice is **a senior associate briefing a junior colleague on the file**. It is warm and brief, and it tells you the move first. It stays inside the paper register ([ADR 0005](../adr/0005-the-register-is-the-paper.md)). This is the voice of the note in the margin, not a replacement for the paper.

## Rules

1. **The move comes first.** Say what to do, or what the reader is looking at, before anything else. After that, add at most one clause of *why*, and only if it changes what the reader does next.
2. **No aphorism, paradox, or definition by negation.** Say the positive fact. "A blank line means no one has offered on that term", not "Nothing here is zero".
3. **Don't lift sentences from `CONTEXT.md`.** The glossary explains design decisions to developers. Take its vocabulary and none of its prose.
4. **Prose speaks as counsel: "we / our"** for the Team, "the other side", "the Client". **Controls are bare imperatives with no pronoun**: "Share with the team", "Send this offer".
5. **Keep the terms of art and gloss each one once, on first contact, in plain words.** A gloss says what the word literally means, never a metaphor: "countersign it — sign off on it as well", not "a second pair of eyes". The gloss goes in the margin: see *Where a gloss sits*.
6. **Anything that ends a Day or the game states that consequence first**, before the price.
7. **Every refusal ends with what the reader can still do.**
8. **Every number carries its unit**: "2 exchange points", never "2 exchange".
9. **One idea per sentence.** Contractions are welcome ("we'd", "it's"). Sentence length was never the fault, so don't cut for length alone. Cut the concepts stacked into one sentence.

### Where a gloss sits

Decided in [Where does a gloss sit on first contact?](https://github.com/MattMencel/bizlaw/issues/399). Four placements were prototyped on the branch [`prototype/gloss-placement`](https://github.com/MattMencel/bizlaw/tree/prototype/gloss-placement): inline, a margin note, a footnote and a definitions list.

- **A note in the left margin, level with the word.** The word itself gets a dotted underline. The note gives the term and its gloss: "countersign — sign off on it as well". A heading, a label or a button can carry one, and that is where students meet most terms. The left margin is used because the term sheet's right margin already shows what the Client wants.
- **On a narrow screen, a list of the terms at the top of the front matter** ("Words used in this file"). There is no room for a margin, so each glossed word links up to its entry.
- **Not inline.** A parenthesis can't hang off a label or a button, so a term met only on a control would never be glossed.
- **First contact is the first place the term appears in reading order on the page**, and every visit glosses it again. Nothing records which student has seen what: the empty states are the tutorial, and there is no progress flag. Two teammates always read the same sheet. The front of the draft and the back of the file each gloss their own first contact.
- **Footnotes stay open for the Instructor's surface.** A numbered note at the foot of the Minute suits its terser voice. That is decided when the Minute's copy is rewritten.

### The Instructor

The Minute is terse and has no "we". It says what a power does, when to use it, and what can't be undone. It never states the design principle behind the power.

## Before and after

| Rule | Before | After |
|---|---|---|
| 1, 3 | You have not asked. Consulting your Client is the only read you get on how far they have actually moved, and it costs a point of preparation — which is why it is an instrument for an occasion rather than a habit. | Check in with the Client when something has changed. It costs 1 preparation point, and it's the only way to see how far they'll move. |
| 2 | Nothing yet. When the other Side executes an offer, any exhibit riding it is served on you and appears here. It is how you learn you have been argued at — never what the argument was worth. | Nothing's been served on us yet. When the other side sends an offer with Exhibits attached, we get copies here. If one arrives, check in with the Client — it may have moved them. |
| 1, 2 | No Term is on the table. Nothing here is zero — an offer of nothing is a position somebody took, and nobody has taken one. | Nobody has offered anything yet. Tick the terms we want below and put figures on them. A blank line means no one has offered on that term, not that they offered zero. |
| 2, 4 | Struck through, their last committed offer. Write ours on the same line. The margin is the Client's. Where there is nothing, nobody has said anything. | Their latest offer is crossed out. Write ours next to it. The margin shows what the Client wants. |
| 5, 9 | Everything here is the case file — work it in any order. The Day ends when both Sides have committed it, and an Offer commits only over a teammate's countersignature. | Work the file in any order. Before we send an offer, a teammate has to countersign it — sign off on it as well. The Day ends once both teams are done. |
| 1 | Your team is still reading the last one. | Not shared yet — the team still sees our last version. |
| 4 | Put this on the table | Share with the team |
| 4 | Countersigned by: Ray Okonkwo *(under a blank line)* | Waiting on a countersignature from: Ray Okonkwo |
| 6, 8 | 2 exchange · 0 exchange left after · this also commits your Day | Ends our Day. Costs 2 exchange points (0 left after). |
| 7, 8 | Today's half will not cover it. | We're out of exchange points today. Preparation points can still buy Actions. |
| Instructor | A team whose other members are absent can draw an offer it cannot execute. Releasing the second lets that team execute alone, for this Day only. It is granted, never exercised — nobody countersigns on a team's behalf — and it cannot be taken back. | Lets a team send its offer without a teammate's countersignature. Today only. Use it when teammates are absent. Cannot be undone. |

The refusal "There is no draft to execute. Write your terms above and put them on the table first." already follows rule 7 and is its model — once it takes the words below: "There is no draft to send. Write our terms above and share them with the team first."

## An Offer's words, stage by stage

Decided in [What does sending an Offer get called, if not "execute"?](https://github.com/MattMencel/bizlaw/issues/392); see [ADR 0009](../adr/0009-an-offer-is-sent-not-executed.md). One word per stage, and never a later stage's word on an earlier one.

| Stage | Words | Never |
|---|---|---|
| Staged — our team sees it | a **draft**; "Share with the team"; "Not shared yet" | *on the table*, *executed* |
| Signing the draft | "Signed by"; "Waiting on a countersignature from: …"; "Countersigned by" once someone has signed | *Executed by* |
| Sent — the other side has it | **send**: "Send this offer", "Sent an offer", a "Sent · Day n" stamp; their offer is "open on the table" | *execute*, *commit* |
| Accepted | "Accept their offer" | — |
| The agreement | the **executed** instrument: "Executed on Day n", "Executed by" | — |

*Commit* belongs to the Day alone.

## Not decided here

- **One name per concept, and capitalisation** (audit category 5).
- **Legal accuracy**, which is judged separately ([Is the game's copy right as contract law?](https://github.com/MattMencel/bizlaw/issues/387)).
