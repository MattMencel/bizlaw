<!--
  The term sheet: the centre of the draft, and the only place the two Sides'
  positions are set against each other.

  `TermsBoard` keeps three ways to be silent distinct and so does this — a Term
  nobody has tabled, a Position with no figure, and a Client with no aspiration
  are three different cells, never one zero. Par is never shown.

  Whether this reads as paper or as a diff view is an open question against
  #315's grammar; the table is what #344 shipped and what axe has passed.
-->
<script>
  let { term_sheet, letterhead, countersignature } = $props()
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
      <thead>
        <tr>
          <th scope="col">Term</th>
          <th scope="col">Ours</th>
          <th scope="col">Theirs</th>
          <th scope="col">What she asked for</th>
        </tr>
      </thead>
      <tbody>
        {#each term_sheet.tracks as track (track.term)}
          <tr>
            <th scope="row" class="term">{track.label}</th>
            <td>
              {#if track.ours}
                {track.ours.money ? track.ours.amount : "Included"}
              {:else}
                <span class="silent">silent</span>
              {/if}
            </td>
            <td>
              {#if track.theirs}
                <span class="theirs">{track.theirs.money ? track.theirs.amount : "Included"}</span>
              {:else}
                <span class="silent">silent</span>
              {/if}
            </td>
            <td class="asp">
              {#if track.aspiration}
                {track.aspiration.money ? track.aspiration.amount : "Asked for"}
              {:else}
                <span class="silent">—</span>
              {/if}
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

  table.terms {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
  }
  table.terms th[scope="col"] {
    text-align: left;
    font-family: var(--mono);
    font-size: 10px;
    font-weight: 400;
    text-transform: uppercase;
    letter-spacing: 0.09em;
    color: var(--muted);
    border-bottom: 1px solid var(--ink);
    padding: 0 10px 5px 0;
  }
  table.terms td,
  table.terms th[scope="row"] {
    padding: 7px 10px 7px 0;
    border-bottom: 1px solid var(--rule);
    vertical-align: top;
    text-align: left;
    font-weight: 400;
  }
  .term {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  /* Redline is the register's mark for their position, and it is decoration
     only: the column header is what says whose it is, so nothing here depends
     on seeing the strike or the colour. */
  .theirs {
    color: var(--redline);
    text-decoration: line-through;
    text-decoration-color: rgba(142, 38, 25, 0.5);
  }
  .silent {
    color: var(--muted);
    font-style: italic;
  }
  .asp {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
  }
  .note {
    font-style: italic;
    color: var(--muted);
  }
</style>
