# Copy inventory: every player-facing string

Resolves [#385](https://github.com/MattMencel/bizlaw/issues/385), part of the map [#384](https://github.com/MattMencel/bizlaw/issues/384). Taken against `origin/main` at `0c814ef`.

This is an inventory only. It does not judge the copy or rewrite it. That is [#386](https://github.com/MattMencel/bizlaw/issues/386) (voice audit) and [#387](https://github.com/MattMencel/bizlaw/issues/387) (contract-law accuracy).

**Method.** I read every file that can put text on a page: the two locale files, every `.svelte` file under `app/frontend`, every read under `app/reads`, the demo controllers, `app/views/layouts`, `public/*.html`, `db/cases/reference.yml` and `lib/demo/seed.rb`. I grepped `app` and `lib` for `I18n.t` and for refusal symbols (`:the_*`, `:an_*`, `:there_*`) and traced each symbol to its sentence. I checked the Ruby formatting helpers with `bin/rails runner`: `"nda".humanize` returns `Nda`, `number_to_currency` returns `$40,000`, `Date#to_s` returns `2026-03-04`, and a missing refusal key returns `Translation missing: en.reads.refusals.…`. I did not render the pages.

**Surfaces.** The WorkingDraft page is `/demo/:run(/:seat)`. From top to bottom it has the masthead, the front matter (the Morning Briefing), the term sheet with its clip rail, the draw row, the countersignature block, the acceptance block, the Consult memo and the Action slip. Its back is the back of the file: the Case File ("the papers") and the Docket. The executed instrument (`Demo/ExecutedInstrument`) replaces the page once the run settles. The Minute (`/demo/:run/instructor`) is the Instructor's only page.

**Kinds.** *interface* = fixed copy describing the machine. *refusal* = a sentence saying why an act can't be taken. *authored* = Case fiction from `reference.yml`. *seed* = demo fiction from `lib/demo/seed.rb`. *composed* = text produced by Ruby or JS code, such as formatting, humanizing or interpolation, with no sentence stored anywhere.

**Reader.** *student*, *Instructor*, or *both*.

---

## 1. Summary

### Count per source

| Source | Entries | Reachable by a player | Notes |
|---|---:|---:|---|
| `config/locales/reads.en.yml` | 37 leaf strings | 32 | 5 unreachable or never rendered (§4) |
| `config/locales/en.yml` | 1 | 0 | Rails scaffold `hello: "Hello world"` |
| Svelte literals, `app/frontend/**/*.svelte` | 119 entries (several are ternary pairs, e.g. "Turn the page over / Turn back to the draft") | 119 | all hardcoded; none go through i18n |
| Ruby-composed text, `app/reads/*`, `Typeset` | 9 mechanisms | 9 | these produce visible text but store no sentence (§2.4) |
| Missing locale key (would render as a raw i18n error) | 1 | 0 (claimed) | `an_exhibit_has_already_been_played` (§4) |
| `db/cases/reference.yml` (authored fiction) | 29 prose strings + 7 Term keys + 5 aspiration figures | all | Term keys and figures reach the page only through Ruby formatting |
| `lib/demo/seed.rb` (seed fiction) | 7 | 6 | `Demo College` is never rendered |
| Layout and PWA (`app/views`) | 2 | 1 | `<title>Skeleton</title>` fallback |
| Rails default error pages, `public/*.html` | 5 pages (10 strings) | 404 on unmatched routes, 500 on crashes | app 404s use `head :not_found`, which has an empty body |
| **Total inventoried** | **≈210 entries** | | |

### Headline: most of the copy is not in `reads.en.yml`

`reads.en.yml` holds 37 strings. The Svelte components hold **119 entries of hardcoded English**. That includes every heading, every button, the table captions, the sr-only table headers, the aria-labels, two client-side refusals and the Instructor's whole Minute. There are also nine Ruby and JS mechanisms that put text on the page without a sentence stored anywhere. Two things are wrong about what the repo says of itself:

- The comment at `FrontMatter.svelte:6-10` and the one at `reads.en.yml:21-25` both say the three Morning Briefing empty states were "the only two student-facing sentences left in a component" until #368. That was only true of *empty states*. Every other sentence a student reads in a component is still there.
- The header of `reads.en.yml` (lines 3-9) says that everything describing the machine lives in that file. Most of the machine's copy is actually in Svelte.

### Strings found outside `reads.en.yml`

**Svelte literals (interface copy):**

- Masthead (working draft): "You are looking at the draft." / "You are looking at the back of the file."; "Turn the page over" / "Turn back to the draft"; `Day n/of`; `<title>` "{matter} — Day n"
- Front matter: "Front matter · the morning of Day n", "Landed today", "Served on you", "Served", "What you started with", "Your client said, on the day you sat down", "The calendar", the calendar's sr-only "Day n, date, today/closed", "n Days, a to b. An Action's lead time is only plannable against how many are left.", "How you are graded"
- Term sheet: "Draft terms of settlement", "Not yet on the table", "Draft — not executed", "Executed", "{matter} · Day n · drawn by …", both captions, four sr-only column headers, "Included", "Asked for", the money field's aria-label
- Draw row: "Covering note", placeholder "Without prejudice…", "Put this on the table", "Your team is still reading the last one."
- Client-side refusals (not in `reads.refusals`): "An offer names at least one term.", "An offer of money is worth an amount."
- Clip rail: "Clipped to this draft", "Played", "Exhibit", the footnote about riding and service
- Countersignature block: "Executed by", "Drawn by", "Countersigned by", "Countersignature waived by the instructor", "Refused", "Execute this draft", the stub line "… left after · this also commits your Day", "Confirm", "Cancel", aria-label
- Acceptance block: "Their offer, open on the table", "The terms struck through on the sheet above, drawn by … and committed on Day n.", "Refused", "Accept their offer", "no cost", "Countersigned by", "… countersigns ·", "this closes Day n and settles the matter · there is nothing after it", "Confirm", "Cancel", aria-label
- Consult memo: "Memo — your Client", "Reads {band}"
- Action slip: "Slip — what this Day will still buy · …", "Refused", "lands today" / "lands Day n", "Spend", the stub line, "Confirm", "Cancel", two aria-labels
- Back of the file: "Back of the file", "What we know, and what we have done", "The papers", "Served", "Exhibit", "Exhibit played", "In hand at the open", "Day n", "The docket", "· the Client reads …", "… · lands Day n", "no cost"
- Executed instrument: "You are looking at the executed agreement.", "Turn back to the agreement", "Settled · …", `<title>` "… — settled", "Terms of settlement", "Executed", the caption "Executed on Day n, date. These are the terms both Sides signed; there is nothing else on this instrument.", "Term" / "As agreed", "Included", "Executed by", "For the {Role}", "Signed by", "Countersigned by", "Countersignature waived by the instructor", "Your Client"
- **The whole Minute (Instructor):** "Minute of the instructor", "Waiver of the second", the waiver rubric paragraph, "a position is on the table, unexecuted", "nothing drawn on the table", "The second is waived for this Day. Granted by …", "Waive the second", "The matter is closed", "The two Sides settled on Day n, … No further Day opens, and there is nothing left to release.", "· this Day has closed", titles and meta

**Ruby- and JS-composed text (no sentence stored anywhere):**

- **Term labels** come from `Typeset#label_for`, which is `key.humanize`. So `nda` renders as **"Nda"**, `reference_letter` as "Reference letter", and so on. No authored label exists anywhere. The `reads.en.yml` header says Term labels belong to the Case, but `reference.yml` authors only the key.
- **Money** comes from `Typeset#money`, which is `number_to_currency` with the Rails default `en` format, e.g. `$40,000`.
- **In-fiction dates** are `Date#to_s`, which is ISO format: **`2026-03-04`**. They appear in the letterheads, the calendar line, the execution stamp and the Minute.
- **Side role**: the raw `"plaintiff"` / `"defendant"` is capitalized in JS for the letterheads and "For the Plaintiff". It stays lowercase in the Minute's aria-label "Waive the second for the plaintiff".
- **Waiver timestamp**: the browser formats it with `toLocaleString` (`Minute.svelte:67-73`), so it depends on the viewer's locale.
- **User names** and the **Case name** come straight from the database (see §2.6 and §2.5).
- **Separators and joins**: " · " joins everywhere, the rubric is `dimensions.join(" · ") + ". " + bonus`, and "—" stands in for a missing ordinal.
- **Body paragraphs** are split on `"\n\n"` in Svelte. YAML `|` blocks contain no blank lines, so each authored body renders as one paragraph with hard line breaks folded into spaces by HTML.
- **CSS `text-transform: uppercase`** changes how a string looks on screen compared with its source. It applies to `.doc-sub` headings, `.stamp`, `.control` buttons, `.cap` captions, `.tab-clip`, `.draft-mark`, the memo's "Reads …" line and the flip buttons. A reviewer reading the source sees "Landed today"; the student sees "LANDED TODAY".

**Strings no single place owns:**

- **"Included"** is written three times: `TermSheet.svelte:61`, `TermSheet.svelte:142` and `ExecutedTerms.svelte:53`.
- **"Countersignature waived by the instructor"** is written three times: `reads.docket.acts.second_waived`, `Countersignature.svelte:99` and `Signatures.svelte:45`. Only the first comes from the locale file.
- **"Executed" / "Executed by" / "Countersigned by" / "Confirm" / "Cancel" / "Refused" / "no cost" / "Served" / "Exhibit"** are each hardcoded in two to four components.
- **"Without prejudice"** appears both as the seed's covering note and as the note field's placeholder (`Draft.svelte:168`). A cold-open student is prompted with the defendant's own wording.
- The **refusal vocabulary is split**. Server refusals are in `reads.refusals`. The two draw-row refusals are hardcoded in `Draft.svelte:102-104`, and the Minute's Day-closed suffix is hardcoded in `Minute.svelte:95`.

---

## 2. Tables per source

Column key: **Loc** = file:line or YAML key. **String** = verbatim; `{x}` marks an interpolated value; `[…]` marks my truncation.

### 2.1 `config/locales/reads.en.yml`

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `reads.morning_briefing.landed.empty` (l.27) | Nothing yet. An Action you spend comes back on the Day its lead time names, and lands here that morning. Nothing you have bought is due back today. | front matter | student | interface (empty state) |
| `reads.morning_briefing.served.empty` (l.32) | Nothing yet. When the other Side executes an offer, any exhibit riding it is served on you and appears here. It is how you learn you have been argued at — never what the argument was worth. | front matter | student | interface (empty state) |
| `reads.morning_briefing.what_you_start_with.empty` (l.40) | Nothing. Your Team was handed no documents at the open, so everything you come to know is something you bought or something they served on you. | front matter | student | interface (empty state), **unreachable in the reference Case** |
| `reads.morning_briefing.grammar` (l.44) | Everything here is the case file — work it in any order. The Day ends when both Sides have committed it, and an Offer commits only over a teammate's countersignature. | front matter (foot) | student | interface |
| `reads.morning_briefing.rubric.dimensions[0]` (l.50) | Settlement quality, 40 points | front matter, "How you are graded" | student | interface |
| `reads.morning_briefing.rubric.dimensions[1]` (l.51) | Legal strategy, 30 points | front matter | student | interface |
| `reads.morning_briefing.rubric.dimensions[2]` (l.52) | Collaboration, 20 points | front matter | student | interface |
| `reads.morning_briefing.rubric.dimensions[3]` (l.53) | Efficiency, 10 points | front matter | student | interface |
| `reads.morning_briefing.rubric.bonus` (l.54) | Creative terms, up to 10 points above the 100. Your grade is released by your instructor; nothing about it is visible before then. | front matter | student | interface |
| `reads.docket.empty` (l.58) | Nothing yet. Every Action your Team spends on lands here — what it was, which of you spent it, what it cost, and the Day its result arrives. Read forward, this is your Team's calendar. | back of the file / Docket | student | interface (empty state) |
| `reads.docket.acts.offer_staged` (l.63) | Drew a draft | Docket line | student | interface |
| `reads.docket.acts.offer_committed` (l.68) | Executed the draft | Docket line | student | interface |
| `reads.docket.acts.offer_accepted` (l.69) | Accepted their offer | Docket line (visible only on the executed instrument's back, since acceptance settles the run) | student | interface |
| `reads.docket.acts.second_waived` (l.70) | Countersignature waived by the instructor | Docket line | student | interface |
| `reads.consult_memo.empty` (l.72) | You have not asked. Consulting your Client is the only read you get on how far they have actually moved, and it costs a point of preparation — which is why it is an instrument for an occasion rather than a habit. | Consult memo | student | interface (empty state) |
| `reads.bands.firm` (l.83) | firm | Consult memo ("Reads firm"), Docket ("· the Client reads firm") | student | interface |
| `reads.bands.ready` (l.84) | ready | Consult memo, Docket | student | interface |
| `reads.refusals.an_offer_has_already_been_committed_today` (l.108) | Your team has already executed an offer today. | countersignature block; term sheet (staging refusal) | student | refusal |
| `reads.refusals.the_budget_cannot_cover_it` (l.110) | Today's half will not cover it. | Action slip; countersignature block | student | refusal |
| `reads.refusals.the_day_has_closed` (l.112) | This Day has closed. | Action slip; term sheet; countersignature; acceptance block; **Minute** | both | refusal |
| `reads.refusals.the_day_has_not_opened` (l.114) | This Day has not opened yet. | Action slip; countersignature | student | refusal, **likely unreachable from the UI** (§4) |
| `reads.refusals.the_offer_has_not_been_seconded` (l.116) | A teammate has to countersign the draft before it can be executed. | countersignature block | student | refusal |
| `reads.refusals.the_acceptance_has_not_been_seconded` (l.122) | A teammate has to countersign before their offer can be accepted. | acceptance block | student | refusal |
| `reads.refusals.the_matter_has_already_settled` (l.128) | The matter has already settled. There is nothing left to accept. | acceptance block | student | refusal, **carried but never rendered** (§4) |
| `reads.refusals.there_is_no_offer_on_the_table` (l.130) | There is no draft to execute. Write your terms above and put them on the table first. | countersignature block | student | refusal |
| `reads.refusals.the_result_would_land_past_the_last_day` (l.133) | Its result would arrive after the last Day of the calendar. | Action slip | student | refusal |
| `reads.refusals.the_simulation_has_settled` (l.135) | The matter has settled. There is nothing left to buy. | Action slip; term sheet | student | refusal, **carried but never rendered** (§4) |
| `reads.case_file.empty` (l.138) | Nothing yet. What your Actions turn up lands here, along with anything the other Side puts in front of you. This is what your Team knows, as against the Docket's what your Team has done. | back of the file / Case File | student | interface (empty state), unreachable in the reference Case, since both Sides hold documents at the open |
| `reads.terms_board.empty` (l.143) | No Term is on the table. Nothing here is zero — an offer of nothing is a position somebody took, and nobody has taken one. | term sheet | student | interface (empty state) |
| `reads.action_board.kinds.consult_client` (l.148) | Consult the Client | Action slip; Docket line | student | interface |
| `reads.action_board.kinds.request_documents` (l.149) | Request documents | Action slip; Docket | student | interface |
| `reads.action_board.kinds.research_precedent` (l.150) | Research precedent | Action slip; Docket | student | interface |
| `reads.action_board.kinds.manage_press` (l.151) | Manage the press | Action slip; Docket | student | interface |
| `reads.action_board.kinds.depose_witness` (l.152) | Depose a witness | Action slip; Docket | student | interface |
| `reads.action_board.kinds.retain_expert` (l.153) | Retain an expert | Action slip; Docket | student | interface |
| `reads.action_board.halves.preparation` (l.155) | preparation | Action slip; countersignature price; Docket | student | interface |
| `reads.action_board.halves.exchange` (l.156) | exchange | Action slip heading; countersignature price/stub; Docket | student | interface |

`config/locales/en.yml:31` has `hello: "Hello world"`. It is Rails scaffold and nothing reads it.

### 2.2 Svelte literals: the working draft (student)

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `pages/Demo/WorkingDraft.svelte:99` | `Day {day}/{of}` · {in_fiction_date} · {you} | masthead | student | interface + composed |
| `pages/Demo/WorkingDraft.svelte:106` | `<title>` {matter} — Day {day} | browser tab | student | interface |
| `pages/Demo/WorkingDraft.svelte:113` | {Role} · {matter} | masthead h1 | student | composed (JS capitalize of `side.role`) |
| `pages/Demo/WorkingDraft.svelte:118` | You are looking at the draft. / You are looking at the back of the file. | masthead | student | interface |
| `pages/Demo/WorkingDraft.svelte:121` | Turn the page over / Turn back to the draft | masthead button | student | interface |
| `components/WorkingDraft/FrontMatter.svelte:17` | Front matter · the morning of Day {day} | front matter h2 | student | interface |
| `FrontMatter.svelte:19` | Landed today | front matter h3 | student | interface |
| `FrontMatter.svelte:30` | Served on you | front matter h3 | student | interface |
| `FrontMatter.svelte:36` | Served | front matter stamp | student | interface |
| `FrontMatter.svelte:41` | What you started with | front matter h3 | student | interface |
| `FrontMatter.svelte:58` | Your client said, on the day you sat down | front matter h3 | student | interface |
| `FrontMatter.svelte:66` | The calendar | front matter h3 | student | interface |
| `FrontMatter.svelte:71` | Day {n}, {date}, today / , closed | calendar (sr-only) | student | interface |
| `FrontMatter.svelte:78-80` | {n} Days, {first date} to {last date}. An Action's lead time is only plannable against how many are left. | front matter | student | interface + composed |
| `FrontMatter.svelte:83` | How you are graded | front matter h3 | student | interface |
| `components/WorkingDraft/TermSheet.svelte:61` | Included | term sheet (a non-money Position, ours or struck theirs) | student | interface |
| `TermSheet.svelte:63` | Asked for | term sheet margin (aspiration without a figure) | student | interface |
| `TermSheet.svelte:70` | Draft terms of settlement | term sheet h2 | student | interface |
| `TermSheet.svelte:72` | Not yet on the table | term sheet mark | student | interface |
| `TermSheet.svelte:74` | Draft — not executed | term sheet mark | student | interface |
| `TermSheet.svelte:76` | Executed | term sheet mark | student | interface |
| `TermSheet.svelte:80` | {matter} · Day {day} · drawn by {name} | term sheet sub-head | student | interface + composed |
| `TermSheet.svelte:96-97` | Struck through, their last committed offer. Write ours on the same line. The margin is the Client's. Where there is nothing, nobody has said anything. | term sheet caption (writable) | student | interface |
| `TermSheet.svelte:99-100` | Struck through, their last committed offer. Written in, ours. The margin is the Client's. Where there is nothing, nobody has said anything. | term sheet caption (read-only) | student | interface |
| `TermSheet.svelte:105` | Term | term sheet (sr-only th) | student | interface |
| `TermSheet.svelte:106` | Their last committed position | term sheet (sr-only th) | student | interface |
| `TermSheet.svelte:107` | Our position | term sheet (sr-only th) | student | interface |
| `TermSheet.svelte:108` | What the Client asked for | term sheet (sr-only th) | student | interface |
| `TermSheet.svelte:138` | Our position on {label}, in dollars | term sheet money input (aria-label) | student | interface |
| `TermSheet.svelte:142` | Included | term sheet (hand-written, aria-hidden) | student | interface (duplicate of l.61) |
| `components/WorkingDraft/Draft.svelte:102` | An offer names at least one term. | draw row | student | **refusal (client-side, not in `reads.refusals`)** |
| `Draft.svelte:104` | An offer of money is worth an amount. | draw row | student | **refusal (client-side, not in `reads.refusals`)** |
| `Draft.svelte:164` | Covering note | draw row label | student | interface |
| `Draft.svelte:168` | Without prejudice… | draw row placeholder | student | interface (echoes the seed note) |
| `Draft.svelte:185` | Put this on the table | draw row button | student | interface |
| `Draft.svelte:190` | Your team is still reading the last one. | draw row | student | interface |
| `components/WorkingDraft/Clipped.svelte:29` | Clipped to this draft | clip rail h2 | student | interface |
| `Clipped.svelte:34` | Played | clip rail tab | student | interface |
| `Clipped.svelte:42` | Exhibit | clip rail tab | student | interface |
| `Clipped.svelte:48-50` | An exhibit rides the offer it is clipped to, and is served on them when the offer is executed. | clip rail foot | student | interface |
| `components/WorkingDraft/Countersignature.svelte:85` | Executed by | countersignature block h2 | student | interface |
| `Countersignature.svelte:91` | Drawn by | countersignature caption | student | interface |
| `Countersignature.svelte:99` | Countersignature waived by the instructor | countersignature caption | student | interface |
| `Countersignature.svelte:104` | Countersigned by: {names} | countersignature caption | student | interface + composed |
| `Countersignature.svelte:117` | Refused | countersignature stamp | student | interface |
| `Countersignature.svelte:138` | Execute this draft | countersignature button | student | interface |
| `Countersignature.svelte:141` | {cost} {half} | countersignature price | student | composed |
| `Countersignature.svelte:155-158` | {cost} {half} · {remaining} {half} left after · this also commits your Day | countersignature stub | student | interface + composed |
| `Countersignature.svelte:163` | Confirm executing this draft | countersignature (aria-label) | student | interface |
| `Countersignature.svelte:166` | Confirm | countersignature stub button | student | interface |
| `Countersignature.svelte:168` | Cancel | countersignature stub button | student | interface |
| `components/WorkingDraft/Acceptance.svelte:86` | Their offer, open on the table | acceptance block h2 | student | interface |
| `Acceptance.svelte:89-90` | The terms struck through on the sheet above, drawn by {name} and committed on Day {n}. | acceptance block | student | interface + composed |
| `Acceptance.svelte:101` | Refused | acceptance stamp | student | interface |
| `Acceptance.svelte:121` | Accept their offer | acceptance button | student | interface |
| `Acceptance.svelte:125` | no cost | acceptance price | student | interface |
| `Acceptance.svelte:136` | Countersigned by | acceptance stub (select label; only with 2+ teammates) | student | interface |
| `Acceptance.svelte:144` | {name} countersigns · | acceptance stub | student | interface + composed |
| `Acceptance.svelte:146` | this closes Day {day} and settles the matter · there is nothing after it | acceptance stub | student | interface |
| `Acceptance.svelte:151` | Confirm accepting their offer | acceptance (aria-label) | student | interface |
| `Acceptance.svelte:154` | Confirm | acceptance stub button | student | interface |
| `Acceptance.svelte:156` | Cancel | acceptance stub button | student | interface |
| `components/WorkingDraft/ConsultMemo.svelte:33` | Memo — your Client | Consult memo h2 | student | interface |
| `ConsultMemo.svelte:44` | Reads {band} | Consult memo | student | interface + composed |
| `components/WorkingDraft/ActionSlip.svelte:74-75` | Slip — what this Day will still buy · {left} {half} · {left} {half} ("—" if no budget) | Action slip h2 | student | interface + composed |
| `ActionSlip.svelte:82` | Refused | Action slip stamp | student | interface |
| `ActionSlip.svelte:87` | {cost} {half} · lands today / lands Day {n} ("—" if none) | Action slip line | student | interface + composed |
| `ActionSlip.svelte:98` | Spend {label} | Action slip (aria-label) | student | interface |
| `ActionSlip.svelte:105` | Spend | Action slip button | student | interface |
| `ActionSlip.svelte:115-119` | {cost} {half} · {remaining} {half} left after · lands today / lands Day {n} | Action slip stub | student | interface + composed |
| `ActionSlip.svelte:124` | Confirm spending {label} | Action slip (aria-label) | student | interface |
| `ActionSlip.svelte:127` | Confirm | Action slip stub button | student | interface |
| `ActionSlip.svelte:129` | Cancel | Action slip stub button | student | interface |
| `components/WorkingDraft/BackOfFile.svelte:16` | Back of the file | back of the file h2 | student | interface |
| `BackOfFile.svelte:17` | What we know, and what we have done | back of the file | student | interface |
| `BackOfFile.svelte:19` | The papers | Case File h3 | student | interface |
| `BackOfFile.svelte:27` | Served | Case File stamp | student | interface |
| `BackOfFile.svelte:28` | Exhibit | Case File tab | student | interface |
| `BackOfFile.svelte:29` | Exhibit played | Case File tab | student | interface |
| `BackOfFile.svelte:30` | In hand at the open | Case File | student | interface |
| `BackOfFile.svelte:31` | Day {n} | Case File | student | interface + composed |
| `BackOfFile.svelte:43` | The docket | Docket h3 | student | interface |
| `BackOfFile.svelte:50` | Day {n} ("—" if none) | Docket line | student | interface + composed |
| `BackOfFile.svelte:52` | — {by} | Docket line | student | composed |
| `BackOfFile.svelte:53` | · the Client reads {band} | Docket line | student | interface + composed |
| `BackOfFile.svelte:57` | {cost} {half} · lands Day {n} | Docket line | student | interface + composed |
| `BackOfFile.svelte:59` | no cost | Docket line | student | interface |

`BackOfFile.svelte` also renders on the executed instrument's back, so its 14 strings appear on both pages.

### 2.3 Svelte literals: the executed instrument (student) and the Minute (Instructor)

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `pages/Demo/ExecutedInstrument.svelte:46` | Settled · {date} · {you} | masthead | student | interface + composed |
| `ExecutedInstrument.svelte:50` | `<title>` {matter} — settled | browser tab | student | interface |
| `ExecutedInstrument.svelte:63-64` | You are looking at the back of the file. / You are looking at the executed agreement. | masthead | student | interface |
| `ExecutedInstrument.svelte:67` | Turn back to the agreement / Turn the page over | masthead button | student | interface |
| `components/ExecutedInstrument/ExecutedTerms.svelte:31` | Terms of settlement | executed instrument h2 | student | interface |
| `ExecutedTerms.svelte:32` | Executed | executed instrument mark | student | interface |
| `ExecutedTerms.svelte:37-38` | Executed on Day {n}, {date}. These are the terms both Sides signed; there is nothing else on this instrument. | executed instrument caption | student | interface + composed |
| `ExecutedTerms.svelte:42` | Term | executed instrument (sr-only th) | student | interface |
| `ExecutedTerms.svelte:43` | As agreed | executed instrument (sr-only th) | student | interface |
| `ExecutedTerms.svelte:53` | Included | executed instrument | student | interface |
| `components/ExecutedInstrument/Signatures.svelte:30` | Executed by | executed instrument h2 | student | interface |
| `Signatures.svelte:35` | For the {Role} | executed instrument | student | interface + composed |
| `Signatures.svelte:38` | Signed by | executed instrument caption | student | interface |
| `Signatures.svelte:45` | Countersignature waived by the instructor | executed instrument caption | student | interface |
| `Signatures.svelte:48` | Countersigned by | executed instrument caption | student | interface |
| `components/ExecutedInstrument/ClientBeat.svelte:30` | Your Client | executed instrument h2 | student | interface |
| `pages/Demo/Minute.svelte:51` | Settled / Day {d}/{of} (· {date} · {you}) | Minute masthead | Instructor | interface + composed |
| `Minute.svelte:77` | `<title>` Minute — settled / Minute — Day {d} | browser tab | Instructor | interface |
| `Minute.svelte:84` | {section} | Minute h1 | Instructor | seed (Section name) |
| `Minute.svelte:89` | Minute of the instructor | Minute h2 | Instructor | interface |
| `Minute.svelte:92` | {matter} · settled on Day {d} | Minute | Instructor | interface + composed |
| `Minute.svelte:94-96` | {matter} · Day {d} of {of} · this Day has closed | Minute | Instructor | interface + composed |
| `Minute.svelte:107` | The matter is closed | Minute h3 | Instructor | interface |
| `Minute.svelte:109-110` | The two Sides settled on Day {d}, {date}. No further Day opens, and there is nothing left to release. | Minute | Instructor | interface + composed |
| `Minute.svelte:115` | Waiver of the second | Minute h3 | Instructor | interface |
| `Minute.svelte:117-120` | A team whose other members are absent can draw an offer it cannot execute. Releasing the second lets that team execute alone, for this Day only. It is granted, never exercised — nobody […] | Minute rubric (truncated; continues "countersigns on a team's behalf — and it cannot be taken back.") | Instructor | interface |
| `Minute.svelte:126` | {Role} | Minute line | Instructor | composed |
| `Minute.svelte:129` | a position is on the table, unexecuted | Minute line | Instructor | interface |
| `Minute.svelte:130` | nothing drawn on the table | Minute line | Instructor | interface |
| `Minute.svelte:135-136` | The second is waived for this Day. Granted by {name}, {toLocaleString time}. | Minute record | Instructor | interface + composed |
| `Minute.svelte:143` | Waive the second for the {role} | Minute (aria-label; role stays lowercase) | Instructor | interface + composed |
| `Minute.svelte:148` | Waive the second | Minute button | Instructor | interface |

### 2.4 Ruby-composed text (`app/reads`, `Typeset`)

These are the mechanisms that turn data into visible text. None of them stores a sentence, so a copy reviewer reading YAML or Svelte would not find these strings.

| Loc | What it produces | Example output | Surface | Reader | Kind |
|---|---|---|---|---|---|
| `app/reads/typeset.rb:48` `label_for(key) = key.humanize` | **Every Term label** | Money, Apology, **Nda**, Reinstatement, Training, Reference letter, Policy change | term sheet, executed instrument, money input aria-label | student | composed |
| `app/reads/typeset.rb:40-44` `money(cents)` | Every figure (positions, aspirations, the draft field's initial value) | `$40,000`, `$250,000`, `$1.50` | term sheet, executed instrument | student | composed |
| `working_draft.rb:113`, `executed_file.rb:69,113`, `minute.rb:86,110`, `working_draft.rb:129` `in_fiction_date.to_s` | Every in-fiction date | `2026-03-04` (ISO) | letterheads, calendar, execution stamp, Minute | both | composed |
| `working_draft.rb:110`, `executed_file.rb:68`, `minute.rb:132` `side.role` | The raw role, capitalized in JS | Plaintiff / Defendant; lowercase in one aria-label | masthead, Signatures, Minute | both | composed |
| `working_draft.rb:109`, `executed_file.rb:67`, `minute.rb:107` `case.name` | The matter name | The Reference Case | masthead, `<title>`, term sheet sub-head, Minute | both | authored (via read) |
| `working_draft.rb:114`, `docket_line` `by`, `countersignature` names | User names | Sam Ortega, Dana Whitfield, … | masthead, term sheet, countersignature, acceptance, Docket, Signatures, Minute | both | seed (via read) |
| `typeset.rb:95-99` `act_label` | A Docket line's act: the commit maps to `offer_committed`, a spend to its kind label, anything else to `reads.docket.acts.*` | Executed the draft / Depose a witness | Docket | student | composed from `reads.en.yml` |
| `working_draft.rb:492-494`, `minute.rb:149-151` `refusal_sentence` | `I18n.t("reads.refusals.#{symbol}")`. **A symbol with no key renders the raw string `Translation missing: en.reads.refusals.<symbol>`**, because `raise_on_missing_translations` is commented out in every environment | see §4 | slip, sheet, countersignature, acceptance, Minute | both | composed from `reads.en.yml` |
| `pages/Demo/Minute.svelte:67-73` `toLocaleString` | Waiver timestamp, in the browser's locale | "Sep 22, 3:14 PM" | Minute | Instructor | composed (JS) |

Controllers (`app/controllers/demo/*`) put **no text** on the page. Refusals travel through the flash as symbols and become sentences only in `WorkingDraft` and `Minute`. Every caller error is `head :not_found`, which has an empty body. The `ArgumentError` messages raised in `OffersController:119-135` and `AcceptancesController:80,95` are rescued into that empty 404 and never shown.

### 2.5 `db/cases/reference.yml` (authored fiction)

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `name` (l.9) | The Reference Case | masthead, `<title>`, term sheet sub-head, Minute | both | authored |
| `clients.plaintiff.opening_statement` (l.97) | Eleven years I gave them, and not one review below "meets expectations". They walked me out through the plant floor like I had stolen something. I want my name back, and I want them to say out loud what they did. | front matter ("Your client said…") | student (plaintiff) | authored |
| `clients.plaintiff.settlement.took_it` (l.102) | I read it three times before I put my name on it. It is not everything I asked for, and I have stopped pretending there was ever a version where it would be. But it is theirs, in wri[…] | executed instrument, "Your Client" | student (plaintiff) | authored (Dialogue Node) |
| `clients.plaintiff.settlement.had_it_taken` (l.107) | They signed it. My number, my words, and their name underneath. Eleven years and it comes down to two pages — but they are my two pages, and nobody handed them to me. Tell me that is really the end […] | executed instrument | student (plaintiff) | authored (Dialogue Node) |
| `clients.plaintiff.bands.firm.lines[0]` (l.139) | No. I have thought about it and the answer is still no. They can keep sending paper over; it does not change what happened on that floor in front of everybody, and it does not change what I am ask[…] | Consult memo | student (plaintiff) | authored (Dialogue Node) |
| `clients.plaintiff.bands.firm.lines[1]` (l.144) | You want me to be reasonable. I have been reasonable for eleven years. I am not moving, and if that makes this take longer then it takes longer — I am not the one who has somewhere to be. | Consult memo | student (plaintiff) | authored (Dialogue Node) |
| `clients.plaintiff.bands.ready.lines[0]` (l.151) | I am tired. I still think I am right, and I am starting to think that being right is not going to be worth what it is costing me. If you can get me something I can live with, bring it and I will l[…] | Consult memo | student (plaintiff) | authored (Dialogue Node) |
| `clients.plaintiff.bands.ready.lines[1]` (l.156) | Ask me what I want and a month ago I would have said all of it. Now I would settle for going one whole day without thinking about them. Get close enough and I will sign, and I would rather that were sooner. | Consult memo | student (plaintiff) | authored (Dialogue Node) |
| `clients.defendant.opening_statement` (l.164) | We followed the policy that was written down, and the policy was there for a reason. What I cannot have is this in the trade press for six months. I want it closed, closed quietly, and closed witho[…] | front matter | student (defendant) | authored |
| `clients.defendant.settlement.took_it` (l.170) | Fine. We take their paper, and we take it today, before somebody decides there is a story here. I am not saying we were wrong. I am saying I have a plant to run and I would very much like to get back[…] | executed instrument | student (defendant) | authored (Dialogue Node) |
| `clients.defendant.settlement.had_it_taken` (l.174) | They signed ours. Good — that is the version I can live with, and it is the one I would have had to stand up and explain. Get it filed, keep it quiet, and let us not be in this room again. | executed instrument | student (defendant) | authored (Dialogue Node) |
| `clients.defendant.bands.firm.lines[0]` (l.185) | We are not paying to make this go away on their terms. The policy was written down, it was followed, and the moment we start negotiating against ourselves every other file in that cabinet becomes a […] | Consult memo | student (defendant) | authored (Dialogue Node) |
| `clients.defendant.bands.firm.lines[1]` (l.190) | My answer has not changed since the first meeting. Tell them we are content to let this run its course. I have a plant to run and I would rather run it than sit here talking about this. | Consult memo | student (defendant) | authored (Dialogue Node) |
| `clients.defendant.bands.ready.lines[0]` (l.197) | All right. I have been through this with the board and I am hearing that the longer it sits, the worse it looks. If there is a version of this that ends quietly and soon, I want to hear it — quietl[…] | Consult memo | student (defendant) | authored (Dialogue Node) |
| `clients.defendant.bands.ready.lines[1]` (l.202) | I would like this closed. Not because they are right, they are not, but because I am spending my week on it and my week is worth something. Find me terms I can put in front of the board without fl[…] | Consult memo | student (defendant) | authored (Dialogue Node) |
| `documents.the_termination_letter.title` (l.236) | The termination letter | front matter; back of the file | student (both Sides) | authored |
| `documents.the_termination_letter.body` (l.237) | Two paragraphs over the plant manager's signature, citing performance concerns raised "on several occasions" and giving the reassignment as the final one. It names no date and attaches nothing. | back of the file | student | authored |
| `documents.the_claimants_own_notes.title` (l.242) | The claimant's own notes | front matter; back of the file | student (plaintiff) | authored |
| `documents.the_claimants_own_notes.body` (l.244) | A pocket diary kept from the reassignment onward: who said what, on which shift, and the two mornings the claimant was sent home early. It is one person's account and reads like one. | back of the file | student (plaintiff) | authored |
| `documents.deposition_of_the_supervisor.title` (l.250) | Deposition of the plant supervisor | front matter; back of the file; clip rail; front matter "Served on you" | student | authored |
| `documents.deposition_of_the_supervisor.body` (l.251) | Asked whether the claimant had been warned before the reassignment, the supervisor produced two dated memoranda and a signed acknowledgement. | back of the file | student | authored |
| `documents.personnel_file.title` (l.262) | The claimant's personnel file | front matter; back of the file; clip rail | student | authored |
| `documents.personnel_file.body` (l.263) | Eleven years of reviews, none below "meets expectations", and no record of the performance concerns raised in the termination letter. | back of the file | student | authored |
| `documents.memorandum_on_comparable_awards.title` (l.274) | Memorandum on comparable awards | front matter; back of the file | student | authored |
| `documents.memorandum_on_comparable_awards.body` (l.275) | Fourteen settlements in this circuit over six years, with the terms each one turned on. Useful to argue from; not a document to put in front of anyone. | back of the file | student | authored |
| `documents.statement_to_the_trade_press.title` (l.281) | The statement given to the trade press | front matter; back of the file | student | authored |
| `documents.statement_to_the_trade_press.body` (l.282) | Four sentences and a name to call, agreed line by line before it went out. It says the matter is in hand and says nothing else; what it is worth is what it stopped being written instead. | back of the file | student | authored |
| `documents.report_of_the_employment_expert.title` (l.288) | The employment expert's report | front matter; back of the file | student | authored |
| `documents.report_of_the_employment_expert.body` (l.289) | Thirty pages on what a plant of this size normally documents before a reassignment, and what this one did. The conclusion is careful and the appendix is where the argument is. | back of the file | student | authored |
| `terms[0..6]` (l.211-217) | money, apology, nda, reinstatement, training, reference_letter, policy_change (keys only, rendered via `humanize`: Money, Apology, **Nda**, …) | term sheet; executed instrument | student | authored key → composed label |
| `clients.*.aspirations` (l.117-119, 179-180) | plaintiff money 250000, apology, reinstatement; defendant money 25000, nda (rendered as `$250,000` / "Asked for") | term sheet margin | student | authored → composed |

Not player-facing: the identifier, licence, version, budget numbers, calendar dates (these reach players only through the ISO formatting in §2.4), `bound`, `portrait_seed` (drawn, never shown as text), band `at` thresholds, and exhibit `shift` / `bears_on`.

### 2.6 `lib/demo/seed.rb` (seed fiction)

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `Seed::SECTION` (l.22) | Business Law 355, Fall 2026 | Minute h1 | Instructor | seed |
| `#player` (l.247) | Sam Ortega | plaintiff masthead ("you"), Docket, term sheet / countersignature "drawn by", Signatures | both | seed |
| `#defendant_lead` (l.250) | Dana Whitfield | defendant masthead, Docket, acceptance block "drawn by …", Signatures | both | seed |
| `#defendant_second` (l.252) | Ray Okonkwo | defendant countersignature "Countersigned by: …", acceptance stub "… countersigns", Signatures | student | seed |
| `#instructor` (l.257) | Professor Adeyemi | Minute masthead; Minute record "Granted by …"; Docket `second_waived` line "— Professor Adeyemi" | both | seed |
| `#the_defendant_moves_first` note (l.209) | Without prejudice. Open for acceptance today. | acceptance block (plaintiff); defendant's read-only term sheet note | student | seed |
| `#the_defendant_moves_first` terms (l.207) | money $40,000 + nda (rendered `$40,000`, "Nda", "Included") | term sheet struck column; executed instrument | student | seed → composed |
| `Seed::ORGANIZATION` (l.21) | Demo College | none (only in developer error messages, l.94) | — | seed, **not rendered** |

### 2.7 Other sources

| Loc | String | Surface | Reader | Kind |
|---|---|---|---|---|
| `app/views/layouts/application.html.erb:4` | Skeleton | `<title>` before Inertia's `<svelte:head>` takes over (visible on first paint without JS) | both | interface (scaffold) |
| `app/views/pwa/manifest.json.erb` | "Skeleton", "Skeleton." | PWA manifest. **Unreachable**: the manifest `<link>` is commented out (layout l.14) | — | scaffold |
| `public/404.html:7,108` | The page you were looking for doesn't exist (404 Not found) / "…You may have mistyped the address or the page may have moved. If you're the application owner check the logs for more information." | unmatched routes only; the demo's own 404s send an empty body | both | Rails default |
| `public/500.html:7,108` | We're sorry, but something went wrong (500 Internal Server Error) / "…If you're the application owner check the logs…" | uncaught errors in production (e.g. `Demo::Seed.simulation` raising "re-run `rake demo:seed`") | both | Rails default |
| `public/422.html`, `public/400.html`, `public/406-unsupported-browser.html` | Rails default titles and one paragraph each | CSRF failure / bad request / old browser | both | Rails default |

`lib/tasks/demo.rake` and `case.rake` print to the terminal and are developer-facing. Portrait SVGs are `aria-hidden` and contain no text.

---

## 3. Surface map (where to look per surface)

| Surface | Sources |
|---|---|
| masthead / letterhead | Svelte (`WorkingDraft`, `ExecutedInstrument`, `Minute`) + case name + seed names + ISO date + capitalized role |
| front matter (Morning Briefing) | `reads.morning_briefing.*` + `FrontMatter.svelte` headings + authored opening statement and document titles |
| term sheet | `reads.terms_board.empty` + `TermSheet.svelte` + humanized Term keys + `money` + seed note |
| clip rail and draw row | `Clipped.svelte`, `Draft.svelte` (including two client-side refusals) + authored document titles |
| countersignature block | `Countersignature.svelte` + `reads.refusals.*` + `reads.action_board.halves.*` + seed names |
| acceptance block | `Acceptance.svelte` + `reads.refusals.*` + seed names and note |
| Consult memo | `reads.consult_memo.empty` + `reads.bands.*` + `ConsultMemo.svelte` + authored band lines |
| Action slip | `reads.action_board.*` + `reads.refusals.*` + `ActionSlip.svelte` |
| back of the file (Case File, Docket) | `reads.case_file.empty`, `reads.docket.*`, `reads.bands.*`, kind labels + `BackOfFile.svelte` + authored document titles and bodies |
| executed instrument | `ExecutedInstrument.svelte`, `ExecutedTerms`, `Signatures`, `ClientBeat` + humanized Terms + authored settlement line |
| Minute (Instructor) | **almost entirely `Minute.svelte`**, plus one refusal key (`the_day_has_closed`) and the seed Section / Instructor names |

---

## 4. Defined but unreachable (or never rendered)

| String / key | Why | Confidence |
|---|---|---|
| `reads.refusals.the_matter_has_already_settled` | `AcceptancesController` carries it and redirects to the draft path. The run is settled by then, so `RunsController#show` renders `Demo/ExecutedInstrument` through `ExecutedFile`, which takes **no refusal argument**. The sentence is written to the flash and never drawn. | High (read the code path; not rendered) |
| `reads.refusals.the_simulation_has_settled` | Same path. `OffersController` (staging) and a commit on a settled run both redirect to a page that renders the executed instrument. `ActionBoard` quotes it, but the slip exists only on an unsettled run. | High |
| `reads.refusals.the_day_has_not_opened` | `SeatedController#quoted_day` notes that only one Day is ever both unclosed and budgeted, and the page always posts the sitting Day. Only a hand-crafted request with a future ordinal can reach it. | Medium to high |
| `reads.morning_briefing.what_you_start_with.empty` | The reference Case hands both Sides `the_termination_letter` at the open. The locale comment (l.36-38) says so too. It is reachable only with a different Case. | High for this Case |
| `reads.case_file.empty` | Same reason: the Case File always holds the documents in hand at the open. | High for this Case |
| `en.hello` ("Hello world") | Rails scaffold; nothing reads it. | High |
| PWA manifest "Skeleton" | The manifest link is commented out. | High |
| `Seed::ORGANIZATION` "Demo College" | Used only for lookup and in developer error messages. | High |
| **Missing key**: `reads.refusals.an_exhibit_has_already_been_played` | `Days::Command#gate_refusal` (command.rb:256) can return it, and it has no sentence. If reached, the countersignature block would print `Translation missing: en.reads.refusals.an_exhibit_has_already_been_played`. The locale comment (l.98-101) says it can't be reached because "an Exhibit cannot yet be played at all". Since #291 and #365 an Exhibit *can* be played, so that premise is stale. It still needs two open Days with drafts carrying the same Exhibit, which `quoted_day`'s invariant suggests can't happen. So it is probably still unreachable, but for a different reason than the comment gives. | Medium |
