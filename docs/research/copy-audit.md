# Copy audit: what is wrong with the player-facing copy

Resolves [#386](https://github.com/MattMencel/bizlaw/issues/386), part of the map [#384](https://github.com/MattMencel/bizlaw/issues/384). Taken against `origin/main` at `0c814ef`, using the inventory from [#385](https://github.com/MattMencel/bizlaw/issues/385) (`docs/research/copy-inventory.md` on `research/copy-inventory`).

This lists findings only. No string has been edited. The suggested rewrites show what each finding means in practice. They are not a proposed voice. Choosing the voice is [#388](https://github.com/MattMencel/bizlaw/issues/388). Legal accuracy is out of scope here and belongs to [#387](https://github.com/MattMencel/bizlaw/issues/387).

**The reader.** An undergraduate in a business law course, reading between classes, on the paper register of ADR 0005: letterhead, term sheet, countersignature block, stamps, docket. Every rewrite stays on that register. Legal terms of art the game teaches (Offer, Exhibit, execute, countersign, serve, the Second) stay in. A finding against one of them is about a missing gloss at first contact, never a case for cutting the term.

---

## Method

**The corpus.** I used every row in the inventory's §2.1 to §2.3, which is 156 rows: 37 locale strings plus 119 Svelte literals. To those I added the Ruby-composed mechanisms in §2.4, the 29 authored prose strings in `db/cases/reference.yml` and the seed note from `lib/demo/seed.rb`. I read each string in its source file, not only in the inventory, because several problems show up only in context. For example, the countersignature caption's meaning depends on the `{#if}` around it.

**Two pools, judged differently.**

- **Sentence-bearing interface copy:** 39 strings of four or more words that describe the machine. 36 are read by students and 3 by the Instructor on the Minute. These carry most of the voice problem, and most of the prevalence figures below are fractions of the 36 student strings.
- **Labels:** headings, buttons, stamps, captions and aria-labels, about 117 rows. I checked them for jargon, inconsistent terms and register breaks, but not for rationale or aphorism, because a two-word heading cannot carry those.

The authored fiction (Client lines and document bodies) is judged in its own short section. It is in character, so long sentences and voice are features there.

**Coding.** I coded each sentence-bearing string once against each category, so one string can count in several categories. I did the coding alone and did not check it against a second reader, so treat the counts as ±1 or 2. The figures that are mechanical:

- **Sentence length.** Split on `.`, `?` and `!` followed by whitespace, then count whitespace-separated words, using a Ruby script over `reads.en.yml` plus the 17 Svelte sentence literals, with interpolations filled with demo values. Result: 67 interface sentences, **mean 10.0 words, median 8, 3 over 20 words, 2 over 25**. The authored fiction has 57 sentences, mean 14.3, with 14 over 20.
- **Term variants.** A regex count over the 156 inventory rows (the `String` column). For example, `\boffer\b` matches 14 rows and `\bOffer\b` matches 1. The counts are quoted in the relevant category.
- **Echoes of the glossary.** I searched `CONTEXT.md` for each empty state's key phrase. Six sentence-bearing strings reproduce a `CONTEXT.md` sentence almost word for word (§ Root cause below).

**Reachability.** Five strings the inventory marks unreachable or never rendered (§4) are still coded, because they will be read in some Case, but they do not count toward "worst surfaces". I did not render the pages.

---

## Summary

| # | Category | Prevalence | Worst surfaces |
|---|---|---|---|
| 1 | **Rationale in place of instruction.** The copy explains why the machine works as it does and never names the move. | **10 of 36** student sentence strings, including **all 7** non-refusal empty states | front matter, Consult memo, term sheet, back of the file |
| 2 | **Aphorism, paradox and negation-riddles** | **11 of 36**; "nothing / never / nobody" appears in 16 of 156 rows | front matter, term sheet (empty state and caption), Consult memo, back of the file |
| 3 | **Density: long sentences and stacked clauses** | **5 of 36**. Sentences are short on average (mean 10 words); the load comes from stacked concepts, not length | Consult memo, back of the file, front matter; the Minute's rubric (Instructor) |
| 4 | **Unglossed jargon on first contact.** 4a: legal terms of art (keep them, but gloss). 4b: engine jargon the game coined | **15 of 36** strings; engine jargon in about 20 labels (`half`/`preparation`/`exchange` in 9 rows, `land*` in 7) | Action slip, countersignature stub, front matter, term sheet |
| 5 | **Inconsistent terms, capitals and point of view** | Structural: 6 concept families each have 2 to 4 names, and 4 capitalisation pairs are split | spread everywhere; worst on the term sheet and draw row, where "on the table" is used three ways |
| 6 | **Register breaks.** Machine output, or scaffold text, leaks onto the paper | 7 mechanisms, on every page (Nda, ISO dates, "1 exchange", aria collisions, `Skeleton`) | term sheet, countersignature and slip stubs, every letterhead |
| 7 | **Refusals and empty states that stop at "why"** | **4 of 10** rendered refusals give no next step; the 2 client-side ones state a definition instead of an action | Action slip, countersignature block, draw row |
| — | **Where the register is the cause** (separate section) | 7 findings | countersignature block, headings throughout, the flip, the term sheet caption, the stubs |

The Instructor's Minute is judged separately below against a terser voice. It has one bad paragraph and one term collision.

### Root cause, stated once

The worst strings are transcriptions of `CONTEXT.md`. The glossary explains design decisions to a developer, and the copy inherited its sentences, not only its vocabulary:

| String | `CONTEXT.md` source |
|---|---|
| `reads.docket.empty`: "Read forward, this is your Team's calendar." | § Docket: "Seen forward it is the Team's calendar" |
| `reads.terms_board.empty`: "an offer of nothing is a position somebody took" | § Terms Board: "an offer of nothing is a position they did not take" |
| `reads.case_file.empty`: "as against the Docket's what your Team has done" | § Action Board: "the Case File's *what we know* and the Docket's *what we have done*" |
| `reads.consult_memo.empty`: "an instrument for an occasion rather than a habit" | § Reaction Band: "an instrument used rarely and on an occasion, never a purchase made on a timetable" |
| `BackOfFile.svelte:17`: "What we know, and what we have done" | § Action Board, § Register |
| `reads.morning_briefing.grammar` | § Morning Briefing, transcribed on purpose (ADR 0005, "Paid off") |

Categories 1, 2 and 3 are mostly this one habit. Correcting the glossary would not fix them. The copy needs its own source.

---

## 1. Rationale in place of instruction

**What it looks like.** A string explains how or why the machine behaves, and the student has to work out the move from that. This matches the owner's complaint. It is most common in the empty states, and CONTEXT § Onboarding says those *are* the tutorial ("the empty state is the tutorial"). So the tutorial explains the design and never gives an instruction.

**Prevalence.** 10 of 36 student sentence strings. That includes all 7 empty states that are not refusals: `landed`, `served`, `what_you_start_with`, `docket`, `consult_memo`, `case_file` and `terms_board`, with `terms_board` counted in both categories 1 and 2. The refusals do better: three of them say what has to happen (§7), and `there_is_no_offer_on_the_table` is the best string in the file.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `reads.consult_memo.empty` | "You have not asked. Consulting your Client is the only read you get on how far they have actually moved, and it costs a point of preparation — which is why it is an instrument for an occasion rather than a habit." | The strategy lesson, "use it rarely", comes wrapped in its justification. There is no instruction ("spend Consult the Client, below"), and the key fact, that this is the *only* way to see your Client's mood, is buried in a subordinate clause. | "Your Client's current mood shows here after you consult them. Consulting costs 1 preparation point (Action slip, below). Save it for when something has changed." |
| `reads.morning_briefing.landed.empty` | "Nothing yet. An Action you spend comes back on the Day its lead time names, and lands here that morning. Nothing you have bought is due back today." | Explains the delivery mechanism and never says where Actions are bought. "Nothing" appears twice in three sentences. | "Nothing due today. Results of the Actions you buy on the slip below arrive here on the morning they're due." |
| `reads.terms_board.empty` | "No Term is on the table. Nothing here is zero — an offer of nothing is a position somebody took, and nobody has taken one." | A design rule for developers: a silent Term is not a $0 Term. The student needs to know what to do: tick terms and put them on the table. The table of inputs sits right under this string. | "No offers yet. Tick the terms you want below, fill in an amount for Money, and put it on the table. A blank line means nobody has offered anything on that term, not that they offered zero." |
| `FrontMatter.svelte:78-80` | "{n} Days, {first} to {last}. An Action's lead time is only plannable against how many are left." | Rationale ("plannable against") where an instruction belongs. The student needs a warning: an Action that lands after the last Day is wasted. | "{n} Days, {first} to {last}. Check how many Days are left before buying an Action — a result that arrives after the last Day is lost." |
| `Draft.svelte:102` | "An offer names at least one term." | A refusal phrased as a definition. The student has to translate it into "tick one". | "Tick at least one term first." |

---

## 2. Aphorism, paradox and negation-riddles

**What it looks like.** Epigrams, chiasmus, and lines that define something by what it is not ("never what the argument was worth", "Nothing here is zero", "there is nothing after it"). Each reads well once, and each makes a skimming reader stop to decode it.

**Prevalence.** 11 of 36 student sentence strings. "Nothing / never / nobody / no one" appears in 16 of 156 inventory rows. Some are legitimate uses of "Nothing yet." and some are rhetorical.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `reads.morning_briefing.served.empty` | "Nothing yet. When the other Side executes an offer, any exhibit riding it is served on you and appears here. It is how you learn you have been argued at — never what the argument was worth." | The owner's own example. The last sentence is a riddle. What it means is useful and hidden: you see *that* an Exhibit hit your Client, but not *how hard*, and to find out you have to Consult. | "Nothing yet. When the other side executes an offer with Exhibits attached, those documents are served on you and appear here. They may have moved your Client — Consult your Client to find out how much." |
| `TermSheet.svelte:96-97` (caption, writable) | "Struck through, their last committed offer. Write ours on the same line. The margin is the Client's. Where there is nothing, nobody has said anything." | Four telegraphic sentences, two of them inverted ("Struck through, their…"), and the last is a paradox. This is the legend for the page's main instrument. | "Crossed out: the other side's latest offer. Write your team's terms on the same line. In the margin: what your Client asked for. Blank means nobody has offered anything yet." |
| `reads.docket.empty` | "Nothing yet. Every Action your Team spends on lands here — what it was, which of you spent it, what it cost, and the Day its result arrives. Read forward, this is your Team's calendar." | "Read forward, this is your Team's calendar" is a glossary aphorism (CONTEXT § Docket). It means that future landing dates act as a schedule. | "Nothing yet. Each Action your team buys is logged here: who bought it, the cost, and the Day its result arrives. Upcoming arrival Days double as your team's schedule." |
| `Draft.svelte:190` | "Your team is still reading the last one." | Indirect. What it means (from `unposted` in `Draft.svelte:126`): you have edited the sheet, and your teammates still see the previous version until you press the button. A skimmer will think a teammate is busy reading something. | "Not shared yet — your team still sees your last version. Press Put this on the table to update it." |
| `reads.case_file.empty` | "Nothing yet. What your Actions turn up lands here, along with anything the other Side puts in front of you. This is what your Team knows, as against the Docket's what your Team has done." | Chiastic contrast in legal-memo syntax ("as against the Docket's what…"). The student never needed the contrast. | "Nothing yet. Documents your Actions find, and documents the other side serves on you, are kept here." |

Also in this category: `Acceptance.svelte:146` ("there is nothing after it"), `ExecutedTerms.svelte:37-38` ("there is nothing else on this instrument"), `Draft.svelte:104` ("An offer of money is worth an amount"), and two authored document bodies (§ Authored fiction).

---

## 3. Density: long sentences and stacked clauses

**What it looks like.** A few sentences run long. More often, a sentence of ordinary length carries three new concepts.

**Prevalence.** Low by length. The mean is 10.0 words and only 3 interface sentences exceed 20 words, so **length is not the main problem, and the prototype should not assume it is.** Five of 36 student strings exceed a sentence of 20 words or a total of 30 words. The more common problem is concept load: `reads.morning_briefing.grammar` is 30 words and introduces "case file", "the Day ends", "commit" (twice, with two meanings), "Offer" and "countersignature".

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `reads.consult_memo.empty` | (quoted in §1) | 42 words; one sentence of 38 words with a dash and a "which is why" clause | (see §1) |
| `reads.docket.empty` | "Every Action your Team spends on lands here — what it was, which of you spent it, what it cost, and the Day its result arrives." | 26 words: a list of four inside a dash clause, and "spends on lands" puts two verbs in a row | (see §2) |
| `reads.morning_briefing.grammar` | "Everything here is the case file — work it in any order. The Day ends when both Sides have committed it, and an Offer commits only over a teammate's countersignature." | Five concepts in 30 words. It is the only statement of the rules (CONTEXT § Morning Briefing: "Nothing else in the game states the rules"), and it sits at the *foot* of the front matter, after the rubric. | "How a Day works: do things in any order. Your team can execute one offer a Day, and a teammate must countersign it first. The Day ends when both sides are done." |
| `reads.morning_briefing.what_you_start_with.empty` (unreachable in the reference Case) | "Nothing. Your Team was handed no documents at the open, so everything you come to know is something you bought or something they served on you." | A 25-word "so" clause that restates the other two empty states | "No documents at the start. Anything you learn will come from Actions you buy or papers the other side serves on you." |

---

## 4. Unglossed jargon on first contact

Split in two, because the map's standing preference treats them differently.

### 4a. Legal terms of art (keep them, gloss them once)

**Prevalence.** Execute, serve, Exhibit, countersign, draw, covering note, "without prejudice", instrument. Each appears unglossed in at least one string the student is likely to read before any explanation. **execut\*** matches 17 rows, **countersign\*** 10, **serv\*** 6, **draw/drawn/drew** 6. None of the 36 sentence strings defines any of them. The one place they are explained in effect is `Clipped.svelte:48-50`, and it uses a metaphor ("rides") to do it.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `Countersignature.svelte:138` + stub `:155-158` | "Execute this draft" … "this also commits your Day" | "Execute" (sign and make binding) is the core term the game teaches, and the student meets it on a button. The consequence that matters most, that this ends your team's Day, is the last lowercase clause of a stub. | Button: "Execute this draft". Stub: "Executing sends this offer to the other side and signs it for your team. It also ends your team's Day." |
| `Draft.svelte:168` | placeholder "Without prejudice…" | A term of art, unglossed. It is also the defendant's own seed note (`lib/demo/seed.rb:209`), so the cold open suggests the other side's wording. | Placeholder: "A short note to the other side (optional)". Gloss "without prejudice" where it is first quoted, if the game wants to teach it. |
| `Clipped.svelte:48-50` | "An exhibit rides the offer it is clipped to, and is served on them when the offer is executed." | Three terms of art plus a metaphor ("rides"), with "Exhibit" lowercased. It is the only explanation of Exhibits the student gets, and it is small muted text at the foot of the rail. | "Tick a document to attach it to this offer as an Exhibit. When you execute the offer, the other side is served with a copy — and it can move their Client." |
| `TermSheet.svelte:80`, `Countersignature.svelte:91`, `reads.docket.acts.offer_staged` | "drawn by …", "Drawn by", "Drew a draft" | "Draw" in the sense of "draw up a document" is legal usage. To an undergraduate "Drew a draft" reads as a pun, or as sketching. | Keep "Drawn by" on the signature line, where the register carries it. In the Docket: "Drafted an offer". |

### 4b. Engine jargon the game coined

**Prevalence.** About 20 labels, plus 8 of the 36 sentence strings. These words are neither legal terms nor plain English: **half** (7 rows), **preparation/exchange** used as units (9), **lands / landed** (7), **lead time**, **the open** ("In hand at the open", "at the open"), **Reads {band}**, and the bands **firm / ready** themselves. None is ever defined on the page. The student can see only the prices that use them.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `reads.refusals.the_budget_cannot_cover_it` | "Today's half will not cover it." | "Half" is an internal ledger term (CONTEXT § Action Budget). The student has never been told that the budget has two halves. | "Not enough {preparation/exchange} points left today." |
| `ActionSlip.svelte:74-75` | "Slip — what this Day will still buy · 8 preparation · 2 exchange" | Numbers with no unit, the word "points" missing, and two pools that are never explained. This is where the Budget is taught, and the Budget is "the lesson" (CONTEXT § Onboarding). | "Actions — left today: 8 preparation points · 2 exchange points". Gloss the two pools once, for example: "Exchange points pay for executing offers and attaching Exhibits." |
| `Countersignature.svelte:155-158` | "{cost} {half} · {remaining} {half} left after · this also commits your Day" → "2 exchange · 0 exchange left after · this also commits your Day" | "2 exchange" is not a phrase. | "Costs 2 exchange points (0 left after). Ends your team's Day." |
| `ConsultMemo.svelte:44`, `BackOfFile.svelte:53`, `reads.bands.*` | "Reads firm", "· the Client reads ready" | "Reads" is gauge language. "Firm" and "ready" are the whole signal from a Consult, and neither is explained. | "Mood: firm (not ready to move)" / "Mood: ready (open to a deal)". The two band words stay; each gets a gloss. |
| `BackOfFile.svelte:30` | "In hand at the open" | "The open" is engine vocabulary for Day 1. | "Had from the start" |

---

## 5. Inconsistent terms, capitals and point of view

**What it looks like.** One concept has several names, one name is used for several concepts, or the capitalisation of a term changes between strings. On a surface that teaches legal vocabulary, each change reads to a student as a different thing.

**Prevalence.** Structural: six concept families, each with two to four names.

- **The act of committing an Offer:** "execute" (17 rows) and "commit" (6 rows). The grammar line says an Offer *commits*, the acceptance block says the offer was *committed* on Day n, and the refusal, the Docket and the button say *execute*.
- **What is on the table:** "on the table" appears in 7 rows with three meanings. It means *staged, visible only to your team* in `Draft.svelte:185` ("Put this on the table") and `TermSheet.svelte:72` ("Not yet on the table"). It means *committed, visible to the other side* in `Acceptance.svelte:86` ("Their offer, open on the table"). It means *anything proposed at all* in `reads.terms_board.empty`.
- **The Second:** students see only "countersign" (10 rows). The Instructor sees only "second" (5 rows, all on the Minute, lowercase). No student-facing string uses "Second", although CONTEXT names the rule that way.
- **The Case File:** "the case file" in the grammar line, "The papers" in `BackOfFile.svelte:19`, and "Case File" nowhere on the page.
- **"Release":** in `reads.morning_briefing.rubric.bonus` it means grade release ("Your grade is released by your instructor"), and on the Minute it means the waiver ("Releasing the second", "nothing left to release"). CONTEXT § Release reserves the word for grades.
- **Capitalisation and point of view:** `Team` 3 rows / `team` 3; `Client` 8 / `client` 1; `Offer` 1 / `offer` 14; `Exhibit` 3 / `exhibit` 2; `Instructor` 0 / `instructor` 5. Pronouns: "we/our/ours" in 5 rows (the term sheet and the back of the file), "you/your" in 20, and "them/their/they" in 12, against "the other Side" in 2.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `Draft.svelte:185` | "Put this on the table" | Most likely to cause a mistake. It suggests the other side will see the offer. They won't: staging is visible to your own team only (CONTEXT § Offer), and only executing sends it. | "Save as our draft" or "Share with my team" |
| `Acceptance.svelte:89-90` vs `reads.refusals.an_offer_has_already_been_committed_today` | "…drawn by {name} and committed on Day {n}." / "Your team has already executed an offer today." | One act, two verbs, in the same view | "…drawn by {name} and executed on Day {n}." |
| `reads.docket.acts.second_waived`, `Countersignature.svelte:99`, `Signatures.svelte:45` vs `Minute.svelte:115,148` | "Countersignature waived by the instructor" / "Waiver of the second", "Waive the second" | The Instructor waives a "second" and the student is told a "countersignature" was waived. It is one act with two names across two readers, and "instructor" is lowercase while every other role is capitalised. | Pick one noun for both readers. For example, Minute: "Waive the countersignature"; student: "Countersignature waived by the Instructor". |
| `TermSheet.svelte:106-107`, `:96`, `BackOfFile.svelte:17` | "Their last committed position" / "Our position" / "Write ours on the same line" / "What we know, and what we have done" | The page switches between "we" (counsel's voice) and "you / your team" (the app's voice), sometimes in adjacent blocks. | Choose one voice for the paper, for example "your team / the other side", and keep "we" for quoted Client and counsel lines. |
| `reads.morning_briefing.grammar` + `BackOfFile.svelte:19` | "Everything here is the case file" / "The papers" | The glossary term (Case File) is never used as a heading, so a student told about the case file cannot find it. | Heading "Case file", with "The papers" as a subtitle if the register wants it. |

**Related: the grammar line describes an act with no control.** `reads.morning_briefing.grammar` says "The Day ends when both Sides have committed it". No controller calls `Days::Commit` (grep over `app/controllers`), and the only place the page ever commits a Day is the aside in the execution stub ("this also commits your Day"). A team that doesn't want to make an offer is told about an act it cannot find. This may be a feature gap, not a copy fault, but the copy is where the student runs into it.

---

## 6. Register breaks: machine output on the paper

**What it looks like.** Text the paper would never print: a code key humanized, an ISO timestamp, a unit-less counter, a scaffold title, or an aria-label assembled from two imperatives.

**Prevalence.** Seven mechanisms, each on every page it touches (inventory §2.4).

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `app/reads/typeset.rb:48` (`label_for` = `key.humanize`) | "Nda" | A code key humanized. No term sheet prints "Nda". The student sees it on Day 1, in the defendant's opening offer (`lib/demo/seed.rb:207`). | "NDA" or "Confidentiality (NDA)". Authored labels per Term in the Case. |
| `working_draft.rb:113` etc. (`Date#to_s`) | "2026-03-04" in letterheads, the calendar, the execution stamp and the Minute | An ISO date on a letterhead | "4 March 2026" / "March 4, 2026" |
| `ActionSlip.svelte:98,124` | aria-label "Spend Consult the Client" / "Confirm spending Consult the Client" | Kind labels are imperatives (`reads.action_board.kinds.*`), so prefixing another verb makes nonsense for screen-reader users | "Spend on: Consult the Client" / "Confirm: Consult the Client" |
| `Minute.svelte:143` | aria-label "Waive the second for the plaintiff" | The role is lowercase here and capitalised everywhere else (`role()` is applied in visible text only) | "…for the Plaintiff" |
| `app/views/layouts/application.html.erb:4` | `<title>Skeleton</title>` | Scaffold text on first paint | The matter name, or the product name |

Also in this category: the unit-less stubs (§4b), `Countersignature.svelte:104` (see the next section), and `Minute.svelte:67-73`, where the waiver timestamp depends on the browser locale.

---

## 7. Refusals and empty states that stop at "why"

**What it looks like.** The refusal explains the rule and leaves the student to find the next move alone. It matters more here than elsewhere because a refusal appears exactly when the student is stuck.

**Prevalence.** 4 of the 10 rendered refusals give no next step. The 2 client-side refusals state a definition (`Draft.svelte:102,104`). The three good ones (`the_offer_has_not_been_seconded`, `the_acceptance_has_not_been_seconded`, `there_is_no_offer_on_the_table`) show the pattern the rest could follow: say what has to happen.

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `reads.refusals.the_result_would_land_past_the_last_day` | "Its result would arrive after the last Day of the calendar." | "Its" has no antecedent in the slip, and the refusal doesn't say the purchase would be wasted or what to do instead | "Too late: this result would arrive after the last Day. Pick an Action that lands sooner." |
| `reads.refusals.an_offer_has_already_been_committed_today` | "Your team has already executed an offer today." | No next step, and the student may think the Day is over | "Your team has already executed an offer today. You can still spend preparation points; your next offer can go tomorrow." |
| `reads.refusals.the_day_has_closed` | "This Day has closed." | Shown on four surfaces with no hint of what happens next | "This Day has closed. The next Day opens when your instructor starts it." (Wording depends on how Days open, which the demo does not show.) |
| `Draft.svelte:104` | "An offer of money is worth an amount." | A definition, not an instruction | "Enter a dollar amount for Money." |

---

## Where the register is the cause

These findings exist because the copy is correct *as paper*. A real signature block, stub or file jacket would read this way. The trouble is that a student reads them as interface. They are listed separately because fixing them means deciding how far the register bends, and that is a design choice, not an edit.

1. **"Countersigned by: Ray Okonkwo" under a blank line** (`Countersignature.svelte:104`). On paper, the caption under a signature line names the signer. Here the code puts the *eligible* signers there (`may_sign`, `working_draft.rb:235`) before anyone has signed. It reads as a past fact: Ray has countersigned. CONTEXT § Second means the line to teach the rule ("one blank naming the teammates who may sign"), but the caption's form says the reverse. Rewrite: "To be countersigned by: Ray Okonkwo".
2. **"Executed by" as the heading over an unsigned draft's block** (`Countersignature.svelte:85`). It is the right title for an executed instrument's signature block, and on a draft it claims the thing is done. The same heading on `Signatures.svelte:30` is correct. Rewrite on the draft: "Signatures".
3. **Surfaces named by stationery instead of by function.** The headings are "Front matter · the morning of Day n", "Slip — what this Day will still buy", "Back of the file", "The papers", "Memo — your Client", "Clipped to this draft" and "Minute of the instructor". The glossary names (Morning Briefing, Action Board, Case File, Docket) are the ones a professor will use in class, and of those only the Docket gets a heading ("The docket"). "Front matter" and "slip" are publishing and office words most undergraduates won't know. Rewrite pattern: lead with the function and keep the paper name as a subtitle, for example "This morning · Day n" or "Actions (slip)".
4. **The flip narrates state instead of naming what is on the back** (`WorkingDraft.svelte:118-121`: "You are looking at the draft." / "Turn the page over"). This is the risk #315 recorded ("a surface behind a gesture is a surface half the Team never turns to"). The copy follows the page-turn metaphor and never says that the Case File and Docket are behind it. Rewrite: "Turn over: case file & docket".
5. **A legend written as paper prose, because the register was said not to need one.** ADR 0005 chose the paper partly because "not one of them needed a legend". The term sheet then got one anyway, the caption in §2, and wrote it in clipped memo style ("Struck through, their last committed offer.") so it would not look like a legend. A plain key (crossed out = theirs, written in = yours, margin = your Client) would do the job in the register.
6. **Stub-as-receipt hides consequences.** The execution and acceptance stubs (`Countersignature.svelte:155-158`, `Acceptance.svelte:146`) are formatted like tear-off receipts, with middots and all lowercase, so the most serious consequences in the game come last in the smallest type: "this also commits your Day" and "this closes Day n and settles the matter · there is nothing after it". A receipt can still lead with the consequence ("Ends the game: …").
7. **"Tutorial only in empty states" puts the explanation in the fixed copy.** CONTEXT § Second says the rule "is never explained in advance", and § Morning Briefing says "Nothing else in the game states the rules of the machine". Taken together, the few strings allowed to explain have to hold all of the explanation, which is why the empty states in §1 and §2 are dense and argue their case. This is doctrine sitting alongside the register, not ADR 0005 itself. It is flagged here because a voice rewrite alone will not remove the pressure.

Not caused by the register: categories 1 and 2 as written. The paper allows "Nothing yet. Results of Actions you buy arrive here." The aphorisms come from the glossary (§ Root cause), not from the letterhead.

---

## The Instructor's Minute (separate voice)

The Minute has its own terser voice, and this section judges it against that. It is mostly compact and fits the register. Three findings:

| Where | String | Problem | Suggested rewrite |
|---|---|---|---|
| `Minute.svelte:117-120` | "A team whose other members are absent can draw an offer it cannot execute. Releasing the second lets that team execute alone, for this Day only. It is granted, never exercised — nobody countersigns on a team's behalf — and it cannot be taken back." | 45 words, the longest string in the game. The third sentence explains a design principle ("granted, never exercised"). An Instructor needs what it does, when to use it, and that it cannot be undone. | "Lets a team execute its draft without a teammate's countersignature. Today only. Use it when teammates are absent. Cannot be undone." |
| `Minute.svelte:109-110`, `:118` | "…nothing left to release." / "Releasing the second…" | Collides with **Release** (grade release, CONTEXT § Release), which is the word an Instructor will use most | "…no waivers left to grant." / "Waiving the countersignature…" |
| `Minute.svelte:129-130` | "a position is on the table, unexecuted" / "nothing drawn on the table" | "On the table" (see §5) and an inverted participle. The Instructor wants a status. | "Draft waiting for countersignature" / "No draft" |

---

## Authored fiction (`db/cases/reference.yml`), briefly

The Client lines are in character. The long sentences (14 of 57 over 20 words) are voice and fine. Two document bodies break the pattern, in ways that belong to this audit and not to #387:

- `documents.statement_to_the_trade_press.body`: "what it is worth is what it stopped being written instead." This is an aphorism that does not parse. It probably means "its value is the stories it prevented". It is the only authored sentence that is hard to read.
- `documents.memorandum_on_comparable_awards.body`: "Useful to argue from; not a document to put in front of anyone." This is a game rule (this document has no Exhibit property) delivered as fiction, in the negation style of §2. A student might reasonably take it as advice about the negotiation, not as a mechanic. If the rule matters, the paper should mark it, for example a missing "Exhibit" tab together with a line on the rail. It should not sit inside flavour text.

---

## Worst surfaces

Ranked by the number of flagged findings on reachable strings, weighted by how early a student reads them:

1. **Front matter (Morning Briefing).** This is the first thing on Day 1. Two reachable empty states, the calendar line and the grammar line carry 12 flags across categories 1 to 4, and the only statement of the rules is at the bottom.
2. **Term sheet and draw row.** The main instrument. An aphoristic empty state, a riddle for a caption, "Nda", "Put this on the table" (likely misread), and two definition-style refusals: 14 flags.
3. **Consult memo.** One string, but it is the single worst in the game: 4 flags, 42 words, and transcribed from the glossary.
4. **Action slip and countersignature stub.** Unit-less engine jargon ("2 exchange"), "half", and refusals with no next step. This is where the Budget is supposed to be learned.
5. **Countersignature block.** A misleading caption and heading (register-caused, findings 1 and 2), and the Day-ending consequence buried in the stub.
6. **Back of the file.** `docket.empty` and "The papers" / "In hand at the open". It ranks lower only because it sits behind the flip.
7. **Acceptance block, executed instrument.** Mostly clean. There is one stray "committed", and "there is nothing after it" / "nothing else on this instrument".

The Minute, judged separately, has one paragraph to cut and one word ("release") to retire.

## For the prototype ticket (#388)

Suggested sample of 8 to 10 strings that covers every category: `reads.consult_memo.empty`, `reads.morning_briefing.served.empty`, `reads.terms_board.empty`, `TermSheet.svelte:96-97` (caption), `reads.morning_briefing.grammar`, `Draft.svelte:185` + `:190` (button and the unposted note), `Countersignature.svelte:104` + the execution stub, `reads.refusals.the_budget_cannot_cover_it`, and `Minute.svelte:117-120` for the Instructor voice. Keep `reads.refusals.there_is_no_offer_on_the_table` as the control, since it already does what the others should.
