<!--
  The term sheet: the centre of the draft, and the only place the two Sides'
  positions are set against each other.

  One ruled line per Term, in the register #315 asked for and #373 settled by
  looking: their last committed position **struck through in place**, ours
  written on the same line after it, and the Client's aspiration outside the
  text block in a margin. What this replaced was a four-column table — Term /
  Ours / Theirs / What she asked for — which made the reader compare cells
  rather than read a document somebody had marked up.

  The three ways to be silent stay distinct here without a word doing the work,
  which is most of why this register won. `TermsBoard` keeps them apart and so
  does the line:

    · nobody has tabled the Term    → nothing struck, and the line is empty
    · a Position carrying no figure → the word, on the line or struck
    · the Client is indifferent     → the margin is empty

  Par is never shown.

  **Ours is the cell you write in.** #373 settled this sheet as print and it is
  now also the drafting surface, which is the same claim rather than a reversal:
  the register's whole grammar is that the draft *is* the page, and a working
  draft is a document somebody writes on. So the writing happens on the line the
  reading happens on, and the only cell that changes is the one that was always
  ours. A form beneath the sheet would put the position in two places and make
  the reader compare them, which is the defect #373 removed.

  Six of the seven Terms are a checkbox, because a Term is atomic — a public
  apology and a private one are two Terms, never one Term with a setting — so
  being on the sheet is the whole of what there is to say about them.
  `StagedOfferTerm` validates that money and only money carries a figure, and
  that is the seventh.

  It is writable only while a position may still be drawn: `WorkingDraft#may_
  draft?`, which is an open Day on an unsettled run with no Offer committed on
  it yet. An executed sheet is a record, and inputs over it would be a student
  typing on their own signed instrument.

  **It is still a table.** Four columns under a visually hidden `<thead>`, so a
  reader who cannot see the strike is told whose each figure is — the strike and
  the redline colour carry nothing on their own, which is what the axe pass over
  this screen exists to keep true. What the eye gets instead of a header row is
  the `<caption>`, because a header row is the thing that made this a diff view
  and a caption is where a table's reading convention belongs. It is the one
  sentence both readers get.

  **A silence is an empty cell, and all three are empty the same way.** The
  caption says so once rather than every cell saying it for itself: this sheet
  is mostly silence by design — on the Day #332 hands the player, seventeen of
  its twenty-one cells are empty — and filling each one with its own explanation
  would bury the four that say something. The header names the column and the
  cell is blank, which is what a data table means by nothing.
-->
<script>
  import { voiced } from "../../lib/prototypeVoice.js"
  let { term_sheet, letterhead, countersignature, position, unposted } = $props()

  // A Position present without an amount is a Team offering the Term itself —
  // an apology is an apology — so it is a word on the line rather than a zero.
  const written = (position) => (position.money ? position.amount : "Included")

  const asked = (aspiration) => (aspiration.money ? aspiration.amount : "Asked for")
</script>

<section aria-labelledby="term-sheet">
  <div class="sheet-head">
    <!-- Focusable so an act can return the reader here, which is where its
         result is legible: what he wrote is now what the sheet prints. -->
    <h2 class="doc-title" id="term-sheet" tabindex="-1">Draft terms of settlement</h2>
    {#if unposted}
      <span class="draft-mark pending">Not yet on the table</span>
    {:else if term_sheet.ours_staged}
      <span class="draft-mark">Draft — not executed</span>
    {:else if countersignature.executed}
      <span class="draft-mark executed">Executed</span>
    {/if}
  </div>
  <p class="doc-sub">
    {letterhead.matter} · Day {letterhead.day}{#if countersignature.drawn_by}{" "}· drawn by
      {countersignature.drawn_by}{/if}
  </p>

  <!-- The empty state and the inputs are not alternatives: one says nobody has
       taken a position and the other is where you take one, and the cold open is
       the Day both are true. It sits above the sheet rather than over it,
       because it is the tutorial (#368) and a sheet nobody can write on is not
       what Day 1 is. -->
  {#if term_sheet.empty_state}
    <p class="empty-state">{term_sheet.empty_state}</p>
  {/if}
  {#if term_sheet.writable || !term_sheet.empty_state}
    <table class="terms">
      <caption class="rubric">
        {#if term_sheet.writable}
          {voiced("caption_writable", "Struck through, their last committed offer. Write ours on the same line. The margin is the Client's. Where there is nothing, nobody has said anything.")}
        {:else}
          {voiced("caption_read", "Struck through, their last committed offer. Written in, ours. The margin is the Client's. Where there is nothing, nobody has said anything.")}
        {/if}
      </caption>
      <thead class="sr-only">
        <tr>
          <th scope="col">Term</th>
          <th scope="col">Their last committed position</th>
          <th scope="col">Our position</th>
          <th scope="col">What the Client asked for</th>
        </tr>
      </thead>
      <tbody>
        {#each term_sheet.tracks as track (track.term)}
          <tr>
            <th scope="row" class="term">
              {#if term_sheet.writable}
                <label>
                  <input type="checkbox" bind:checked={position.terms[track.term]} />
                  <span>{track.label}</span>
                </label>
              {:else}
                {track.label}
              {/if}
            </th>
            <td class="line struck">
              {#if track.theirs}<s>{written(track.theirs)}</s>{/if}
            </td>
            <td class="line ours">
              {#if term_sheet.writable && track.money}
                <!-- The one Term that carries a figure. Dollars, as typed:
                     the print above it is formatted and this is not, because
                     one is read and one is written into. -->
                <input
                  class="figure"
                  type="text"
                  inputmode="decimal"
                  bind:value={position.amount}
                  disabled={!position.terms[track.term]}
                  aria-label={`Our position on ${track.label}, in dollars`}
                />
              {:else if term_sheet.writable}
                <span class="hand-written" aria-hidden="true"
                  >{position.terms[track.term] ? "Included" : ""}</span
                >
              {:else if track.ours}
                {written(track.ours)}
              {/if}
            </td>
            <td class="margin">
              {#if track.aspiration}<span class="hand">{asked(track.aspiration)}</span>{/if}
            </td>
          </tr>
        {/each}
      </tbody>
    </table>
  {/if}
  {#if term_sheet.note && !term_sheet.writable}
    <p class="small note">{term_sheet.note}</p>
  {/if}
</section>

<style>
  .sheet-head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
  }
  .draft-mark {
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.16em;
    color: var(--redline);
    border: 1px solid var(--redline);
    padding: 2px 6px;
    text-transform: uppercase;
  }
  .draft-mark.executed {
    color: var(--stamp);
    border-color: var(--stamp);
  }
  /* Neither the position on the table nor an executed one: what the reader is
     looking at has not been drawn yet. Dashed for the reason the blank
     countersignature line is — a mark waiting on an act that has not happened. */
  .draft-mark.pending {
    color: var(--muted);
    border-style: dashed;
    border-color: var(--rule-2);
  }
  h2:focus-visible {
    outline: 2px solid var(--stamp);
    outline-offset: 3px;
  }
  /* What a header row would have said, said once in the register's own voice —
     and, being the caption, said to both readers out of one element. */
  caption.rubric {
    text-align: left;
    font-size: 12.5px;
    font-style: italic;
    color: var(--muted);
    padding: 0 0 14px;
  }

  table.terms {
    width: 100%;
    border-collapse: collapse;
    font-size: 15px;
  }
  .term {
    width: 158px;
    text-align: left;
    font-weight: 400;
    font-variant: small-caps;
    letter-spacing: 0.04em;
    padding: 11px 12px 3px 0;
    vertical-align: baseline;
  }
  .term label {
    display: flex;
    gap: 7px;
    align-items: baseline;
    cursor: pointer;
  }
  .term input {
    accent-color: var(--stamp);
  }
  /* The writing space, ruled whether or not anybody has written on it: what a
     reader sees is a line with something on it or a line with nothing, rather
     than two kinds of cell. It is two cells so the hidden header can say whose
     each figure is, and `border-collapse` joins their rules into the one line
     that the strike and the writing both sit on.

     `width: 1%` shrinks the struck cell onto its content, which is what puts
     our figure immediately after theirs instead of in a column of its own. */
  .line {
    border-bottom: 1px solid var(--rule-2);
    padding: 11px 0 3px;
    vertical-align: baseline;
  }
  .struck {
    width: 1%;
    white-space: nowrap;
    padding-right: 10px;
  }
  s {
    color: var(--redline);
    text-decoration-color: rgba(142, 38, 25, 0.55);
  }
  /* The figure is written on the ruled line, not in a box on top of it: the
     cell already carries the rule, so the field brings no border of its own. */
  .figure {
    width: 100%;
    font-family: var(--serif);
    font-size: 15px;
    color: var(--ink);
    background: none;
    border: 0;
    padding: 0;
  }
  .figure:disabled {
    color: var(--muted);
  }
  .figure:focus-visible {
    outline: 2px solid var(--stamp);
    outline-offset: 2px;
  }
  /* Written by the checkbox in the Term column, which is the control a reader
     reaches — so this is the ink it leaves and is not read out twice. */
  .hand-written {
    color: var(--ink);
  }
  /* Past the rule is annotation rather than drafting, which is the whole of the
     difference between a margin and a fourth column: a fixed measure so it
     cannot grow into one, and a smaller hand off the ink of the instrument. */
  .margin {
    width: 132px;
    padding: 11px 0 3px 16px;
    border-left: 1px solid var(--rule);
    vertical-align: baseline;
  }
  .hand {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
  }
  .note {
    font-style: italic;
    color: var(--muted);
    margin-top: 14px;
  }
</style>
