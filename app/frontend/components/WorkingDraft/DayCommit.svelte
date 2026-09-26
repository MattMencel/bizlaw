<!--
  Committing the Day without sending an Offer, at the foot of the front after
  the Action slip (#396). The Morning Briefing says the Day ends when both
  Sides commit, and this is the control that does it.

  It is one player's call: no signature line and no countersignature, because
  committing locks nothing — the Team can still spend and send until the Day
  closes. It costs nothing, and it confirms in place all the same, because on
  a Day the other Side has already committed it ends the Day and every point
  left in it. The stub says that first.

  Once the Side has committed, the block is the record naming who did. Sending
  an Offer commits the Day with it, so on that Day there is only the record.

  `aria-disabled` rather than `disabled`, so the sentence saying why stays in
  the tab order with the control, and a refusal is wired to it by
  `aria-describedby` — the rule every control on this page follows.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { tick } from "svelte"

  let { day_commit, copy, day_commitment_path, day } = $props()

  let open = $state(false)

  const live = $derived(!day_commit.refusal)

  // The refusal the control reads with: the live one where the seam would
  // refuse now, else the one carried back from a press that was refused.
  const describedBy = $derived(
    day_commit.refusal ? "day-commit-refusal" : day_commit.refused ? "day-commit-refused" : undefined
  )

  // Focus goes where the result is legible: this block, which is the record
  // once the commit lands and carries the refusal when it does not. Found by id
  // after the round trip, because the visit re-renders the page — onto the next
  // Day, when this commit closed the one it was pressed on.
  async function restoreFocus() {
    await tick()
    document.getElementById("day-commit")?.focus()
  }

  // The Day rides along for the reason a spend's does: it is the Day the reader
  // saw, and the server asking again could answer with the next one.
  function commit() {
    open = false
    router.post(day_commitment_path, { day }, { preserveScroll: true, onFinish: restoreFocus })
  }
</script>

<section class="day-commit" aria-labelledby="day-commit">
  <h2 class="doc-sub" id="day-commit" tabindex="-1">{copy.heading}</h2>

  {#if day_commit.refused}
    <p class="refusal refused-just-now" id="day-commit-refused">
      <span class="stamp warn">{copy.refused}</span>
      {day_commit.refused}
    </p>
  {/if}

  {#if day_commit.committed}
    <p>{day_commit.record}</p>
  {:else}
    <div class="commit">
      <button
        type="button"
        class="control"
        id="commit-the-day"
        aria-expanded={open}
        aria-controls={open ? "day-commit-stub" : undefined}
        aria-disabled={!live}
        aria-describedby={describedBy}
        onclick={() => live && (open = !open)}
      >
        {copy.commit}
      </button>
      {#if day_commit.refusal}
        <span class="refusal" id="day-commit-refusal">{day_commit.refusal}</span>
      {/if}
    </div>

    {#if open}
      <div class="stub" id="day-commit-stub">
        <p class="terms">{day_commit.stub}</p>
        <button type="button" class="control confirm" aria-label={copy.confirm_label} onclick={commit}>
          {copy.confirm}
        </button>
        <button type="button" class="control" onclick={() => (open = false)}>{copy.cancel}</button>
      </div>
    {/if}
  {/if}
</section>

<style>
  /* Focus lands on the heading after the round trip, and a heading is not
     normally a focus target: the ring is what says so. */
  .day-commit .doc-sub:focus-visible {
    outline: 2px solid var(--ink);
    outline-offset: 3px;
  }
  .commit {
    display: flex;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
  }
  .refused-just-now {
    margin-bottom: 0;
  }
</style>
