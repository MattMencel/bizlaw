---
paths:
  - app/frontend/**
  - app/controllers/demo/**
  - app/reads/**
  - lib/demo/**
  - config/locales/**
  - spec/system/**
---

# The demo surface

The demo renders a Day as a working draft on paper, the grammar of ADR 0005 and `CONTEXT.md` § Register. The front is today's working state; the Case File and the Docket are its back, turned over rather than navigated to.

**Seats.** `Demo::Seat` resolves a URL segment to the `(user, side)` pair every seam's `by:` needs, against the cast `Demo::Seed` publishes. The bare URL is the plaintiff player; `instructor` sits over no Side and signs nothing, because § Second forbids signing for a Team. A seat is not Attribution: `Side#members` answers who has acted, so `WorkingDraft` takes the reader as an argument. `second_waivers` stays outside the members fold so a waiver cannot make the Instructor a teammate.

**Composers.** `WorkingDraft`, `ExecutedFile` and `Minute` turn domain objects into props — Days into ordinals, Users into names, money into a formatted string, dates through `I18n.l`, and every engine symbol into its sentence from `reads.*`. `Typeset` holds the marks they print (figures, Term labels, roles, dates, documents, Docket lines, the portrait size), so there is one currency decision.

**No English in a `.svelte` file.** A page's fixed labels arrive as its `copy` subtree; any sentence carrying a value is composed in Ruby with interpolation. Copy lives in one locale file per surface under `config/locales/`. `spec/frontend/no_english_in_components_spec.rb` and `spec/reads/refusal_sentences_spec.rb` enforce both halves.

**Writes carry intent, never a price or a row id.** A spend posts the Action's kind and `apply` quotes inside the request that charges. Offers and Acceptances name things by the Case's vocabulary, Case File identifiers and the Day an Offer was committed on, because the seed reset moves row ids. A refusal writes nothing: it rides the flash as the engine's symbol on a shelf keyed by act and seat, and the composer makes it a sentence.

**Controls.** A control the Team cannot use now is `aria-disabled`, not `disabled`, so the sentence saying why stays in the tab order, and a refusal is wired to its control by `aria-describedby`. Focus moves to where the act's result is legible. Confirmations open in place on the line — a dialog would be a browser gesture on paper and would hide the other prices while they are being compared.

**The term sheet** is one ruled line per Term: the other Side's last committed position struck through in place, ours written after it, the Client's aspiration past a rule in the margin. It is a `<table>` under a visually hidden `<thead>`, with the reading convention in the `<caption>`. The `ours` cell is the input, writable only while `WorkingDraft#may_draft?`. Edits stay local until one explicit act — a teammate reads this sheet to decide whether to countersign it — and the sheet says *Not yet on the table* while they are pending. Inputs open holding `TermsBoard#ours`; the covering note does not carry forward. The money field shows the printed figure, validated as written against `Demo::OffersController::FIGURE`, which `Draft.svelte` mirrors. Exhibits clip to a rail down the side, gated by `CaseFile#exhibits_available?`.

**Blocks.** The countersignature block always prints its sentence and prices the commit only when a draft is live. The acceptance block is its sibling, shown only when an Offer stands across the table, and reads that Offer from `TermsBoard#their_offer` so the strike and the control mean one Offer. The executed instrument prints no redline and no margin — the aspiration beside the agreed figure would leak Settlement Quality (ADR 0007) — and its stamp is dated in the fiction.

**The Consult memo** sits on the front under the countersignature block. `WorkingDraft` inlines the portrait SVG at size 78: an external SVG behind `<img>` cannot see `--portrait-ink` and `--portrait-paper`. The face prints once, on the newest memo, because `Portraits::Compose#scope` keys element ids to seed, expression and size.

**Cross-tab discovery** is a focus listener, not a subscription. A CSS part moves into `register.css` once three parts use it.

`demo:seed` never renders the written-in half of the register, so a spec that needs it stages a draft. Taking the defendant's Offer on Day 3 after the waiver ends the demo early by design: a waiver releases the Second for a Side for a Day, not for an act.
