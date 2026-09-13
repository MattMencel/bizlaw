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
  let { term_sheet, letterhead, countersignature } = $props()

  // A Position present without an amount is a Team offering the Term itself —
  // an apology is an apology — so it is a word on the line rather than a zero.
  const written = (position) => (position.money ? position.amount : "Included")

  const asked = (aspiration) => (aspiration.money ? aspiration.amount : "Asked for")
</script>

<section aria-labelledby="term-sheet">
  <div class="sheet-head">
    <h2 class="doc-title" id="term-sheet">Draft terms of settlement</h2>
    {#if term_sheet.ours_staged}
      <span class="draft-mark">Draft — not executed</span>
    {:else if countersignature.executed}
      <span class="draft-mark executed">Executed</span>
    {/if}
  </div>
  <p class="doc-sub">
    {letterhead.matter} · Day {letterhead.day}{#if countersignature.drawn_by}{" "}· drawn by
      {countersignature.drawn_by}{/if}
  </p>

  {#if term_sheet.empty_state}
    <p class="empty-state">{term_sheet.empty_state}</p>
  {:else}
    <table class="terms">
      <caption class="rubric">
        Struck through, their last committed offer. Written in, ours. The margin is the
        Client's. Where there is nothing, nobody has said anything.
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
            <th scope="row" class="term">{track.label}</th>
            <td class="line struck">
              {#if track.theirs}<s>{written(track.theirs)}</s>{/if}
            </td>
            <td class="line ours">
              {#if track.ours}{written(track.ours)}{/if}
            </td>
            <td class="margin">
              {#if track.aspiration}<span class="hand">{asked(track.aspiration)}</span>{/if}
            </td>
          </tr>
        {/each}
      </tbody>
    </table>
  {/if}
  {#if term_sheet.note}
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
  /* Past the rule is annotation rather than drafting, which is the whole of the
     difference between a margin and a fourth column: a fixed measure so it
     cannot grow into one, and a smaller hand off the ink of the instrument. */
  .margin {
    width: 148px;
    padding: 11px 0 3px 18px;
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
