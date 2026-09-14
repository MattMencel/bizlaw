<!--
  The countersignature block, permanently under the term sheet — present before
  there is anything to sign, because an empty signature line is how the Day
  teaches that a commit needs a second hand.

  **The dead control is the lesson, not a defect.** On a Side of one the blank
  line names nobody and Execute cannot be pressed, and that is the beat the whole
  demo was built around: the rule is never explained in advance, and an unsigned
  line on the draft in your own hand teaches it where fixed copy elsewhere would
  not. So it is a form that cannot be executed yet rather than a greyed button —
  `aria-disabled` and not `disabled`, so the sentence saying why stays in the tab
  order with the control it describes, the way an unaffordable Action's does.

  It also prints what executing would cost. The price and the refusal together
  are the beat — *this would take your whole exchange half, and you cannot
  execute it alone* — and either half alone is not: a price with no obstacle
  reads as a button, and an obstacle with no price hides the trade-off the
  exchange half exists to force, which on this Case is one point for the Offer
  and one for each Exhibit clipped to it.

  The sentence is always owed; the price is not. Under an executed instrument
  the block is a record — both lines filled, nobody left to sign — and it says
  nothing at all. On a Day with nothing drawn it says there is no draft to
  execute and prints no figure, because a price for a position that does not
  exist is a number with nothing under it.

  The Execute control itself is still inert: the commit lands with the waiver, in
  #366. So it is `aria-disabled` unconditionally rather than only where the quote
  refuses — an Instructor's waiver is the one thing that clears that refusal, and
  a control that went live-looking there would be pressable and do nothing. When
  #366 gives it a handler the condition becomes the refusal, and the waived case
  becomes the one state in which it can actually be pressed.

  Nothing grants a waiver from any surface yet, so that state is not reachable
  today; this is what keeps it from becoming reachable and wrong on the same
  commit.
-->
<script>
  let { countersignature } = $props()

  const execution = $derived(countersignature.execution)
</script>

<section class="countersign" aria-labelledby="countersign">
  <h2 class="doc-sub" id="countersign">Executed by</h2>
  <div class="sig-lines">
    <div class="sig">
      <div class="line">
        {#if countersignature.drawn_by}<span class="hand">{countersignature.drawn_by}</span>{/if}
      </div>
      <div class="cap">Drawn by</div>
    </div>
    <div class="sig">
      <div class="line" class:blank={!countersignature.signed_by}>
        {#if countersignature.signed_by}<span class="hand">{countersignature.signed_by}</span>{/if}
      </div>
      <div class="cap">
        {#if countersignature.waived}
          Countersignature waived by the instructor
        {:else}
          Countersigned by{#if countersignature.may_sign.length}: {countersignature.may_sign.join(", ")}{/if}
        {/if}
      </div>
    </div>
  </div>
  {#if !countersignature.executed}
    <div class="execution">
      <button
        type="button"
        class="control execute"
        id="execute-the-draft"
        aria-disabled={true}
        aria-describedby={execution?.refusal ? "execution-refusal" : undefined}
      >
        Execute this draft
      </button>
      {#if execution?.cost}
        <span class="price">{execution.cost} {execution.half_label}</span>
      {/if}
      {#if execution?.refusal}
        <span class="refusal" id="execution-refusal">{execution.refusal}</span>
      {/if}
    </div>
  {/if}
</section>

<style>
  .countersign {
    border: 1px solid var(--rule-2);
    padding: 14px 16px;
    background: var(--paper-2);
  }
  .countersign .doc-sub {
    margin-top: 0;
  }
  .sig-lines {
    display: flex;
    gap: 26px;
    margin: 12px 0 8px;
  }
  .sig {
    flex: 1;
  }
  .sig .line {
    border-bottom: 1px solid var(--ink);
    height: 26px;
  }
  /* The second line is dashed until somebody can sign it: the difference
     between a line waiting for a hand and a line nobody may put one on. */
  .sig .line.blank {
    border-bottom-style: dashed;
    border-color: var(--rule-2);
  }
  .sig .hand {
    font-family: "Snell Roundhand", "Apple Chancery", cursive;
    font-size: 20px;
    padding-left: 4px;
    line-height: 26px;
  }
  .sig .cap {
    font-family: var(--mono);
    font-size: 10px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 0.07em;
    padding-top: 4px;
  }
  .execution {
    display: flex;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
    padding-top: 4px;
  }
  .price {
    font-family: var(--mono);
    font-size: 11.5px;
    color: var(--muted);
  }
  .refusal {
    font-size: 12.5px;
    color: var(--redline);
  }
</style>
