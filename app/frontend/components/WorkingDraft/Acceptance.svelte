<!--
  Their paper, on our page — and the one act taken on it.

  An Acceptance *is* a countersignature on the other Side's instrument (ADR
  0007), and #373 settled that their instrument reaches this page as a strike
  through our own line and in no other form: it is not in the Case File, which
  answers what we know, and not in the front matter, which is what arrived. So
  there was nothing here shaped like their paper to sign. This block is what
  gives it one.

  **It names the instrument and never restates it.** The terms are the strike
  column on the sheet above; printing them again would put one position in two
  places and make the reader compare them, which is the defect #373 removed and
  #365 was corrected for reintroducing. `TermsBoard#their_offer` is the same row
  that column is folded from, so a control here can never accept an Offer other
  than the one struck through up there.

  It prints their covering note, which until now nothing did. The defendant's
  reads *Without prejudice. Open for acceptance today.* — and the Day it says
  that of has closed by the time it can be taken, which is the register telling
  the reader a deadline passed rather than a line of copy about one.

  **It is not a permanent fixture, and the countersignature block is.** That
  block is about a draft this Team could always draw, and its empty signature
  line is the lesson. There is no lesson in a control for paper nobody has
  served, so this is absent until there is something across the table — the same
  gate the Exhibit rail uses.

  It confirms in place, in the slip's grammar. Where the commit's stub prints a
  price this one prints the consequence: an Acceptance costs nothing at all,
  which makes it the cheapest act on the board to reach and the only one that
  cannot be followed by anything. A control that fired on a single press would
  make the ending cost less than a Consult.

  The seconder is named in the stub rather than chosen on the line. It is the
  one act in the demo where the Second is *satisfied* rather than waived — the
  defendant's Side has two members who have both acted — and a Team with several
  eligible teammates picks there, where the reader is already agreeing to what
  the act does.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { tick } from "svelte"

  let { acceptance, copy, acceptance_path, day } = $props()

  const live = $derived(!acceptance.refusal)

  let open = $state(false)
  // Whoever the stub will name. A Side with one eligible teammate — which is
  // every Side the demo renders — never sees a choice; the state exists so that
  // a Side with several is a pick rather than a silent first.
  let signing = $state(acceptance.may_sign[0]?.email ?? null)

  // Focus goes where the act's result is legible, which for this act is two
  // different documents. A refusal comes back to this block, with the sentence
  // wired to the control by `aria-describedby`. An Acceptance that lands comes
  // back to the executed instrument, where this block does not exist at all —
  // so the landing is that sheet's own title, and focusing it is also what
  // scrolls a sighted reader to the top of a page that just got much shorter
  // underneath a preserved scroll position.
  async function restoreFocus() {
    await tick()
    const landing =
      document.getElementById("executed-terms") ?? document.getElementById("acceptance")

    landing?.focus()
    landing?.scrollIntoView({ block: "start" })
  }

  // The Day this closes, the Day their Offer was committed on, and the hand
  // countersigning. No price, because there is none — and no terms, because
  // `Offers::Accept` is handed the instrument the Day names and reads the deal
  // off it.
  function accept() {
    open = false
    router.post(
      acceptance_path,
      { day, committed_on: acceptance.committed_on, seconded_by: signing },
      { preserveScroll: true, onFinish: restoreFocus }
    )
  }
</script>

<section class="acceptance" aria-labelledby="acceptance">
  <h2 class="doc-sub" id="acceptance" tabindex="-1">{copy.heading}</h2>

  <p class="small">{acceptance.drawn}</p>

  <p class="small">{copy.house_rule}</p>

  {#if acceptance.note}
    <!-- Their covering line, in their hand and not ours. Indented as quoted
         matter, because it is another firm's words on our copy of their paper. -->
    <blockquote class="covering">{acceptance.note}</blockquote>
  {/if}

  {#if acceptance.refused}
    <p class="refusal refused-just-now" id="acceptance-refused">
      <span class="stamp warn">{copy.refused}</span>
      {acceptance.refused}
    </p>
  {/if}

  <div class="taking">
    <button
      type="button"
      class="control"
      id="accept-their-offer"
      aria-expanded={open}
      aria-controls={open ? "acceptance-stub" : undefined}
      aria-disabled={!live}
      aria-describedby={acceptance.refusal
        ? "acceptance-refusal"
        : acceptance.refused
          ? "acceptance-refused"
          : undefined}
      onclick={() => live && (open = !open)}
    >
      {copy.accept}
    </button>
    <!-- No price beside it. The commit prints one here and this has none to
         print: the largest thing a Team ever does for nothing. -->
    <span class="price">{copy.no_cost}</span>
    {#if acceptance.refusal}
      <span class="refusal" id="acceptance-refusal">{acceptance.refusal}</span>
    {/if}
  </div>

  {#if open}
    <div class="stub" id="acceptance-stub">
      <p class="terms">
        {#if acceptance.may_sign.length > 1}
          <label>
            {copy.countersigned_by}
            <select bind:value={signing}>
              {#each acceptance.may_sign as member (member.email)}
                <option value={member.email}>{member.name}</option>
              {/each}
            </select>
          </label> ·
        {:else if acceptance.countersigns}
          {acceptance.countersigns} ·
        {/if}
        {acceptance.consequence}
      </p>
      <button
        type="button"
        class="control confirm"
        aria-label={copy.confirm_label}
        onclick={accept}
      >
        {copy.confirm}
      </button>
      <button type="button" class="control" onclick={() => (open = false)}>{copy.cancel}</button>
    </div>
  {/if}
</section>

<style>
  /* Their paper is set off from ours rather than continuous with it: the sheet
     above is this Team's draft, and a block that shared its ground would read as
     another section of the same document. */
  .acceptance {
    border: 1px solid var(--rule-2);
    border-left: 3px solid var(--stamp);
    padding: 12px 16px;
    background: var(--paper-2);
  }
  .acceptance .doc-sub {
    margin-top: 0;
  }
  /* Focus lands here after the round trip, and a heading is not normally a
     focus target: the ring is what says so to a reader who can see it. */
  .acceptance .doc-sub:focus-visible {
    outline: 2px solid var(--ink);
    outline-offset: 3px;
  }
  .acceptance p.small {
    margin: 0 0 8px;
  }
  .covering {
    margin: 0 0 10px;
    padding-left: 12px;
    border-left: 1px solid var(--rule-2);
    font-style: italic;
    font-size: 14px;
    color: var(--muted);
  }
  .taking {
    display: flex;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
  }
  /* The block's own: a choice of hand, which no other stub offers. */
  .stub select {
    font-family: var(--mono);
    font-size: 11.5px;
  }
</style>
