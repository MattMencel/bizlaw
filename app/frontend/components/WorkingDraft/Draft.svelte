<!--
  The position, and the one act that puts it on the table.

  The term sheet and what is clipped to it are one object, so one component owns
  them: `Offers::Stage` replaces the Terms and the Exhibits together because the
  teammate who Seconds is confirming the whole play, and a control that could
  move the ammunition without the Terms would be handing them half of it. This
  file is what holds the two halves in one hand — the sheet through the middle,
  the clip rail down the side, and the act along the foot of both.

  **Edits are local until the act.** Staging costs nothing and is ungated, so
  there is nothing to confirm and no price to quote; the reason it is still one
  deliberate press rather than a field that posts itself is the Second. A
  teammate reads this sheet to decide whether to countersign it, and a position
  that reshaped itself under them mid-read is the thing the Second exists to
  prevent. It also keeps the Docket's `offer_staged` line meaning one drawing
  rather than one keystroke.

  Which is why the sheet says so while they are pending: *Not yet on the table*
  replaces the draft mark, because *what you are reading is not what your
  teammate is reading* is the one thing the register must not leave to an
  input's internal state. Only the mark — the changed lines are not marked. The
  redline on this sheet is theirs, and a second one competing with it would be
  two arguments in one colour.

  The pending position is re-seeded by remounting: the page keys this component
  on the server's own answer, so a staging that lands wipes the edits it landed
  and a staging that is refused leaves them exactly where they were, under the
  sentence saying why.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { tick, untrack } from "svelte"
  import TermSheet from "./TermSheet.svelte"
  import Clipped from "./Clipped.svelte"

  let { term_sheet, clipped, letterhead, countersignature, offer_path, day } = $props()

  const moneyTrack = term_sheet.tracks.find((track) => track.money)

  // What the inputs open holding, from the props the sheet is printed from — so
  // the writing and the print under it can never start out disagreeing.
  //
  // `untrack` because the initial value is the whole intent: these props change
  // only when the server's answer does, and the page remounts this component on
  // exactly that, so following them here would overwrite a student's edits with
  // an answer they have not seen.
  let position = $state(
    untrack(() => ({
      terms: Object.fromEntries(term_sheet.tracks.map((t) => [t.term, t.draft.on])),
      amount: moneyTrack?.draft.amount ?? "",
      exhibits: Object.fromEntries(clipped.documents.map((d) => [d.identifier, d.clipped])),
      note: term_sheet.note ?? ""
    }))
  )

  const named = (of) => Object.keys(of).filter((key) => of[key])

  const drawn = $derived(named(position.terms))

  // A figure as a student would write one: an optional currency symbol, digits
  // either plain or grouped in threes, at most two decimal places. The same
  // grammar the controller holds — `Demo::OffersController::FIGURE` — because a
  // figure this control lets through and the server refuses is a 404 where the
  // reader should have had a dead control and a sentence.
  //
  // It is matched against what was **typed**, not against the stripped digits: a
  // malformed figure with its separators taken out is a well-formed different
  // one, so `1,50` would pass as `150` and put $150 on the table in place of
  // $1.50, silently, on the one instrument whose whole subject is how much money
  // changes hands.
  const FIGURE = /^\$?(\d{1,3}(?:,\d{3})*|\d+)(?:\.\d{1,2})?$/

  // The figure with its notation off. This is what crosses the wire and what the
  // comparison below is made on — `$180,000` and `180000` are one position, and
  // a comparison that kept the notation would read them as two. It is never what
  // decides whether the figure is well formed.
  const bare = (typed) => String(typed ?? "").replace(/[,$\s]/g, "")

  const figure = $derived(bare(position.amount))

  // The note as the server will hold it. `params[:note].presence` turns a note
  // of nothing but spaces into no note at all, so a client that compared what
  // was typed would see a difference the server had already thrown away: the
  // post lands, `term_sheet.note` does not move, the page is not remounted, and
  // the sheet goes on saying *Not yet on the table* about a position that is on
  // it. Trimmed here, posted trimmed, and compared trimmed, so all three agree
  // on what the note is.
  const tidy = (written) => String(written ?? "").trim()

  const owesAnAmount = $derived(position.terms[moneyTrack?.term] === true)

  const wellFormed = $derived(FIGURE.test(position.amount.trim()))

  // Why the act cannot be taken, or null. `Offers::Stage` refuses an Offer
  // naming no Term and `StagedOfferTerm` refuses money without a figure; both
  // are caller faults there rather than refusals a student should read, so the
  // control is what has to make them unreachable — and it says which, because a
  // dead control that will not say why is the thing #363 ruled out.
  const withheld = $derived(
    drawn.length === 0
      ? "An offer names at least one term."
      : owesAnAmount && !wellFormed
        ? "An offer of money is worth an amount."
        : null
  )

  const onTheTable = $derived(
    JSON.stringify([
      term_sheet.tracks.filter((t) => t.draft.on).map((t) => t.term),
      bare(moneyTrack?.draft.amount),
      clipped.documents.filter((d) => d.clipped).map((d) => d.identifier),
      tidy(term_sheet.note)
    ])
  )

  const pending = $derived(
    JSON.stringify([
      drawn,
      owesAnAmount ? figure : "",
      named(position.exhibits),
      tidy(position.note)
    ])
  )

  const unposted = $derived(pending !== onTheTable)

  // The act's result is the sheet: what he wrote is now what the sheet prints,
  // and the mark above it has changed. #364's rule is where the result is
  // legible, not the control that was pressed — and on a page this long a
  // keyboard reader left at the top is told nothing about what just happened.
  async function focusTheSheet() {
    await tick()
    document.getElementById("term-sheet")?.focus()
  }

  function draw() {
    if (withheld) return

    router.post(
      offer_path,
      {
        day,
        terms: drawn,
        amount: owesAnAmount ? figure : null,
        exhibits: named(position.exhibits),
        note: tidy(position.note)
      },
      { preserveScroll: true, onFinish: focusTheSheet }
    )
  }
</script>

<div class="drafting" class:railed={clipped.available}>
  <TermSheet {term_sheet} {letterhead} {countersignature} {position} {unposted} />
  {#if clipped.available}
    <Clipped {clipped} {position} />
  {/if}
</div>

{#if term_sheet.writable}
  <div class="drawing">
    <label class="note-field">
      <span class="cap">Covering note</span>
      <input
        type="text"
        bind:value={position.note}
        placeholder="Without prejudice…"
        maxlength="200"
      />
    </label>

    <!-- Dead rather than absent, and `aria-disabled` rather than `disabled`:
         the sentence saying why is the thing a reader who cannot see the greyed
         control most needs to reach, and `disabled` would take it out of the
         tab order along with the control it describes. -->
    <button
      type="button"
      class="control draw"
      id="draw-the-position"
      aria-disabled={!!withheld}
      aria-describedby={withheld ? "withheld" : undefined}
      onclick={draw}
    >
      Put this on the table
    </button>
    {#if withheld}
      <span class="refusal" id="withheld">{withheld}</span>
    {:else if unposted}
      <span class="tiny muted">Your team is still reading the last one.</span>
    {/if}
  </div>
{/if}

{#if term_sheet.refusal}
  <p class="refusal sheet-refusal" role="status">{term_sheet.refusal}</p>
{/if}

<style>
  /* The clip rail is down the side of the instrument, which is where
     `CONTEXT.md` § Register puts it — and it stacks under the sheet rather than
     squeezing it once the measure will not hold both. */
  .drafting {
    display: grid;
    grid-template-columns: 1fr;
    gap: 20px;
    align-items: start;
  }
  /* The column only exists once there is a rail to put in it: a Team that has
     never held an Exhibit gets the full measure rather than a reserved gap,
     which is the same gate `CaseFile#exhibits_available?` is. */
  .drafting.railed {
    grid-template-columns: 1fr 168px;
  }
  @media (max-width: 760px) {
    .drafting.railed {
      grid-template-columns: 1fr;
    }
  }

  .drawing {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
    padding-top: 12px;
  }
  .note-field {
    display: flex;
    align-items: baseline;
    gap: 8px;
    flex: 1;
    min-width: 260px;
  }
  .note-field .cap {
    font-family: var(--mono);
    font-size: 10px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 0.07em;
    white-space: nowrap;
  }
  .note-field input {
    flex: 1;
    font-family: var(--serif);
    font-size: 14px;
    font-style: italic;
    color: var(--ink);
    background: none;
    border: 0;
    border-bottom: 1px solid var(--rule-2);
    padding: 2px 2px 3px;
  }
  .note-field input:focus-visible {
    outline: 2px solid var(--stamp);
    outline-offset: 2px;
  }

  .draw {
    border-color: var(--ink);
  }
  .refusal {
    font-size: 12.5px;
    color: var(--redline);
  }
  .sheet-refusal {
    margin: 8px 0 0;
  }
</style>
