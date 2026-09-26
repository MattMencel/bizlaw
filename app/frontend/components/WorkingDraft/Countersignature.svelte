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

  **The control is now live, and exactly one thing makes it so.** #363's rule
  finally applies to the control that taught it: `aria-disabled` is the quote's
  own refusal rather than an unconditional true. On a Side of one that refusal is
  `the_offer_has_not_been_seconded` and nothing the Team does clears it — the
  Instructor's waiver does, from a tab of their own, and `Second.satisfied?`
  reads it off the Side and the Day so the block needs to know nothing about it
  beyond what the quote already says.

  It confirms in place, in the slip's grammar, and for the slip's reason:
  executing is irreversible, it takes this Team's whole exchange half, and it
  commits the Day with it. The block printing a price standing is #365's beat
  about the trade-off and not an agreement to spend it — skipping the
  confirmation would make the one irreversible act on this page the only one
  that never asks.

  The refusal it carries back is the block's own and sits beside the quote rather
  than inside it, because it outlives the quote. The race this demo actually
  produces is a teammate's commit landing first, which makes this block a record
  and the quote nil on the very read that has to say what happened — without it,
  a reader who pressed Execute gets back an executed instrument he did not
  execute and not one word about it.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { tick } from "svelte"

  let { countersignature, copy, commit_path, day } = $props()

  const execution = $derived(countersignature.execution)
  const live = $derived(!!execution && !execution.refusal)

  let open = $state(false)

  // Focus goes where the act's result is legible, which for this act is the
  // block itself: executing turns it into a record with both lines filled, and
  // a refusal is wired to the control by `aria-describedby`. Found by id after
  // the round trip rather than held, because the visit re-renders this subtree.
  async function restoreFocus() {
    await tick()
    document.getElementById("countersign")?.focus()
  }

  // No price on the wire and no position either: `Days::Command` re-reads the
  // table inside the transaction that charges, so what this costs is decided
  // there. The Day rides along for the reason a spend's does — it is the one
  // part of what he agreed to that the server re-asking would answer
  // *differently* rather than not at all.
  function execute() {
    open = false
    router.post(
      commit_path,
      { day },
      { preserveScroll: true, onFinish: restoreFocus }
    )
  }
</script>

<section class="countersign" aria-labelledby="countersign">
  <h2 class="doc-sub" id="countersign" tabindex="-1">{copy.heading}</h2>
  <div class="sig-lines">
    <div class="sig">
      <div class="line">
        {#if countersignature.drawn_by}<span class="hand">{countersignature.drawn_by}</span>{/if}
      </div>
      <div class="cap">{copy.drawn_by}</div>
    </div>
    <div class="sig">
      <div class="line" class:blank={!countersignature.signed_by}>
        {#if countersignature.signed_by}<span class="hand">{countersignature.signed_by}</span>{/if}
      </div>
      <div class="cap">
        {#if countersignature.waived}
          {copy.waived}
        {:else if countersignature.signed_by}
          {copy.countersigned_by}
        {:else}
          <!-- Each teammate carries a name and the identifier an act posts them
               back by, since #367 gave the Acceptance a hand to name. This line
               only ever reads the names. A blank line never says *countersigned
               by*: under nobody's hand that reads as done. -->
          {countersignature.may_sign_caption || copy.waiting}
        {/if}
      </div>
    </div>
  </div>

  <!-- The refusal outlives the execution block it would otherwise sit in: an
       executed instrument has no price and no obstacle left to name, and is
       exactly the state a refused commit comes back to. -->
  {#if countersignature.refusal}
    <p class="refusal refused-just-now" id="commit-refusal">
      <span class="stamp warn">{copy.refused}</span>
      {countersignature.refusal}
    </p>
  {/if}

  {#if !countersignature.executed}
    <div class="execution">
      <button
        type="button"
        class="control execute"
        id="execute-the-draft"
        aria-expanded={open}
        aria-controls={open ? "execution-stub" : undefined}
        aria-disabled={!live}
        aria-describedby={execution?.refusal
          ? "execution-refusal"
          : countersignature.refusal
            ? "commit-refusal"
            : undefined}
        onclick={() => live && (open = !open)}
      >
        {copy.execute}
      </button>
      {#if execution?.price}
        <span class="price">{execution.price}</span>
      {/if}
      {#if execution?.refusal}
        <span class="refusal" id="execution-refusal">{execution.refusal}</span>
      {/if}
    </div>

    {#if open}
      <!-- Pinned under the block rather than floating over the sheet, for the
           reason the slip's stub is pinned to its line: a confirmation that
           came loose of what it confirms is the dialog #363 rejected, by
           another name. -->
      <div class="stub" id="execution-stub">
        <p class="terms">{execution.stub}</p>
        <button
          type="button"
          class="control confirm"
          aria-label={copy.confirm_label}
          onclick={execute}
        >
          {copy.confirm}
        </button>
        <button type="button" class="control" onclick={() => (open = false)}>{copy.cancel}</button>
      </div>
    {/if}
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
  /* Focus lands here after the round trip, and a heading is not normally a
     focus target: the ring is what says so to a reader who can see it. */
  .countersign .doc-sub:focus-visible {
    outline: 2px solid var(--ink);
    outline-offset: 3px;
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
  /* The block's own: the refusal sits directly under the signature lines, so it
     wants no leading of its own above the control beneath it. */
  .refused-just-now {
    margin-bottom: 0;
  }
</style>
