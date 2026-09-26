<!--
  The deal, as it was fixed. One ruled line per Term and one column: what was
  agreed.

  **The redline and the margin are both gone, and that is the whole difference
  between this sheet and the working one.** They went for one reason each. There
  is no longer a position across the table from this one — there is one
  instrument that both Sides signed — so a strike would be marking up a document
  nobody is still negotiating. And the margin held the Client's aspiration: a
  settled sheet printing the figure on the line with *she asked for $75,000*
  beside it is a Settlement Quality read arriving through the layout, which is
  the leak ADR 0007 spent three refusals closing. It would come in past the copy
  rather than through it, which is exactly how such a thing gets shipped.

  So the three silences the working sheet keeps apart do not arise here. A Term
  that is on this instrument is on it; a Term nobody agreed is simply not a row.
  `CommittedOfferTerm` carries the shape of the deal and nothing about what it
  was measured against.

  It is still a table, and it still has a hidden header: an amount and a word
  are different kinds of cell, and a reader who cannot see the alignment is owed
  the column's name. What replaces the working sheet's rubric caption is the one
  sentence this instrument means — it is executed, and these are its terms.
-->
<script>
  let { copy, terms, stamp } = $props()
</script>

<section aria-labelledby="executed-terms">
  <div class="sheet-head">
    <h2 class="doc-title" id="executed-terms" tabindex="-1">{copy.heading}</h2>
    <span class="draft-mark executed">{copy.mark}</span>
  </div>

  <table class="terms">
    <caption class="rubric">{stamp.caption}</caption>
    <thead class="sr-only">
      <tr>
        <th scope="col">{copy.columns.term}</th>
        <th scope="col">{copy.columns.agreed}</th>
      </tr>
    </thead>
    <tbody>
      {#each terms as term (term.term)}
        <tr>
          <th scope="row" class="term">{term.label}</th>
          <td class="line">
            <!-- A Term agreed without a figure is the Term itself: a settlement
                 including an apology includes an apology. -->
            {term.money ? term.amount : copy.included}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>
</section>

<style>
  .sheet-head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 14px;
    flex-wrap: wrap;
  }
  /* Focus lands on the title when the reader arrives from the act that executed
     it, and a heading is not normally a focus target. */
  .sheet-head .doc-title:focus-visible {
    outline: 2px solid var(--ink);
    outline-offset: 3px;
  }
  .draft-mark {
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--muted);
  }
  .draft-mark.executed {
    color: var(--stamp);
    border: 2px solid var(--stamp);
    padding: 3px 7px;
    font-weight: 700;
    transform: rotate(-2.5deg);
  }

  table.terms {
    width: 100%;
    border-collapse: collapse;
    margin-top: 14px;
  }
  .rubric {
    caption-side: top;
    text-align: left;
    font-size: 13px;
    color: var(--muted);
    padding-bottom: 10px;
  }
  table.terms tr {
    border-bottom: 1px solid var(--rule);
  }
  th.term {
    text-align: left;
    font-weight: 400;
    font-variant: small-caps;
    letter-spacing: 0.04em;
    padding: 9px 12px 9px 0;
    width: 45%;
  }
  td.line {
    padding: 9px 0;
    font-family: var(--mono);
    font-size: 13px;
  }
</style>
