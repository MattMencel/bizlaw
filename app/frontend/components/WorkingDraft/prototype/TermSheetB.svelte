<!--
  PROTOTYPE — variant B: redline in place, aspiration in a true margin.

  One line per Term, read as a marked-up clause rather than as a row of cells:
  the Term in small caps, the other Side's last committed position struck
  through immediately after it, and ours written in beside the strike. Where we
  have taken no position the writing space is a ruled blank, which is what an
  unfilled line on paper is.

  The Client's aspiration hangs **outside** the text block, past a rule, in the
  hand of somebody annotating rather than drafting. That is the axis #373 asks
  about: whether this is a margin or a fourth column by another name.

  Underneath it is still a `<table>` with four columns and a visually hidden
  `<thead>`, so a screen reader is told whose each figure is. The strike is
  decoration only — the hidden header carries the meaning — which is the same
  claim the shipped variant makes and the one the axe pass exists to check.

  The three silences:
    · nobody has tabled the Term   → nothing struck, and a ruled blank
    · a Position carrying no figure → the word, in ink or struck
    · the Client is indifferent     → the margin is empty
-->
<script>
  let { term_sheet, letterhead, countersignature } = $props()

  const written = (position) => (position.money ? position.amount : "Included")
  const margin = (aspiration) => (aspiration.money ? aspiration.amount : "wants it")
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
    <!-- The rubric the hidden header would otherwise have to carry for the eye.
         One sentence of front matter is the paper's way of saying what a
         column head says on a form. -->
    <p class="rubric">
      Struck through, their last committed offer. Written in, ours. The margin is the
      Client's.
    </p>

    <table class="redline">
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
            <th scope="row" class="clause">{track.label}</th>
            <td class="struck">
              {#if track.theirs}<s>{written(track.theirs)}</s>{/if}
            </td>
            <td class="ours">
              {#if track.ours}
                <span class="filled">{written(track.ours)}</span>
              {:else}
                <!-- A ruled blank is a picture. The screen reader is given an
                     empty cell otherwise, and an empty cell is indistinguishable
                     from one it skipped — which is a distinction the shipped
                     table's grey `silent` does make. -->
                <span class="blank"><span class="sr-only">not filled in</span></span>
              {/if}
            </td>
            <td class="margin">
              {#if track.aspiration}<span class="hand">{margin(track.aspiration)}</span>{/if}
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
  .rubric {
    font-size: 12.5px;
    font-style: italic;
    color: var(--muted);
    margin: 0 0 14px;
  }

  table.redline {
    width: 100%;
    border-collapse: collapse;
    font-size: 15px;
  }
  /* Three columns of text block and one of margin. The margin is a fixed
     measure so it stays a gutter rather than growing into a column. */
  .clause {
    width: 158px;
    text-align: left;
    font-weight: 400;
    font-variant: small-caps;
    letter-spacing: 0.04em;
    padding: 9px 12px 9px 0;
    vertical-align: baseline;
  }
  .struck {
    width: 1%;
    white-space: nowrap;
    padding: 9px 10px 9px 0;
    vertical-align: baseline;
  }
  .ours {
    padding: 9px 0;
    vertical-align: baseline;
  }
  /* The rule that makes the gutter a margin and not a fourth column: the text
     block ends here, and what is past it is annotation. */
  .margin {
    width: 148px;
    padding: 9px 0 9px 18px;
    border-left: 1px solid var(--rule);
    vertical-align: baseline;
  }

  s {
    color: var(--redline);
    text-decoration-color: rgba(142, 38, 25, 0.55);
  }
  /* The writing space is ruled whether or not anybody has written on it, so
     what a reader sees is a line with something on it or a line with nothing —
     rather than two different kinds of cell. */
  .filled,
  .blank {
    display: block;
    border-bottom: 1px solid var(--rule-2);
    min-height: 1.05em;
  }
  /* Annotation, not drafting: a smaller hand, off the ink of the instrument. */
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
