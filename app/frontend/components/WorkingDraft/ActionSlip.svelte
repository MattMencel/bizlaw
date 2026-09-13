<!--
  The Action Board as a slip along the foot of the draft. Every Action on the
  authored menu is priced whether or not today will cover it, and a refusal is
  printed beside the one it refuses: what the Day will not buy is as much of the
  Day's shape as what it will.

  It is also where the first act in the game happens. A spend confirms *in
  place* — the line opens into a stub carrying the price, what the half has left
  after it and the Day the result lands, over Confirm and Cancel. A dialog would
  be a browser gesture on a surface #299 settled as paper, and it would take the
  other five prices off the screen at the moment the trade-off between them is
  the thing being decided.

  The page never sends a price. `router.post` carries the Action's kind and the
  Day it was priced on, and `Days::Command` quotes inside the request that
  charges — so a stub read from props that have gone stale can be refused but
  never quietly repriced. The Day rides along because it is the one part of what
  he agreed to that the server re-asking would answer *differently* rather than
  not at all: a Day can close between this page and this press, and the next one
  has a Budget of its own.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { tick } from "svelte"

  let { slip, spend_path, day } = $props()

  // Which Action's stub is open, and one at a time: the whole argument for
  // confirming in place was keeping the other five prices in view, and two open
  // stubs give back exactly what the dialog was rejected for.
  let open = $state(null)

  const toggle = (kind) => (open = open === kind ? null : kind)

  // The round trip re-renders the whole draft, which on a page this long leaves
  // a keyboard reader at the top of the document with no account of what just
  // happened. Focus goes back to the Action's own control, where the refusal —
  // wired to it by `aria-describedby` — is announced along with it. Found by id
  // rather than held as a binding, because the visit may remount this component
  // and a held node would be the old one.
  async function restoreFocus(kind) {
    await tick()
    document.getElementById(`spend-${kind}`)?.focus()
  }

  function spend(kind) {
    open = null
    router.post(
      spend_path,
      { kind, day },
      { preserveScroll: true, onFinish: () => restoreFocus(kind) }
    )
  }
</script>

<section aria-labelledby="slip">
  <h2 class="doc-sub" id="slip">
    Slip — what this Day will still buy ·
    {#each Object.entries(slip.remaining) as [half, r], i}{i ? " · " : ""}{r.left ?? "—"} {r.label}{/each}
  </h2>
  <ul class="plain">
    {#each slip.actions as action (action.kind)}
      <li class="slip" class:refused={!action.affordable}>
        <span class="k">
          {action.label}
          {#if action.refused_just_now}<span class="stamp warn">Refused</span>{/if}
        </span>
        <span class="p">
          {action.cost}
          {action.half_label} ·
          {action.lands_today ? "lands today" : `lands Day ${action.landing_day ?? "—"}`}
        </span>

        <!-- Present and dead rather than absent, and `aria-disabled` rather
             than `disabled`: a disabled button leaves the tab order, and the
             sentence saying why this one cannot be bought is the thing a reader
             who cannot see the greyed line most needs to reach. -->
        <button
          type="button"
          class="control"
          id={`spend-${action.kind}`}
          aria-label={`Spend ${action.label}`}
          aria-expanded={open === action.kind}
          aria-controls={open === action.kind ? `stub-${action.kind}` : undefined}
          aria-disabled={!action.affordable}
          aria-describedby={action.refusal ? `refusal-${action.kind}` : undefined}
          onclick={() => action.affordable && toggle(action.kind)}
        >
          Spend
        </button>

        {#if action.refusal}
          <span class="refusal" id={`refusal-${action.kind}`}>{action.refusal}</span>
        {/if}

        {#if open === action.kind}
          <div class="stub" id={`stub-${action.kind}`}>
            <p class="terms">
              {action.cost}
              {action.half_label} ·
              {action.remaining_after}
              {action.half_label} left after ·
              {action.lands_today ? "lands today" : `lands Day ${action.landing_day}`}
            </p>
            <button
              type="button"
              class="control confirm"
              aria-label={`Confirm spending ${action.label}`}
              onclick={() => spend(action.kind)}
            >
              Confirm
            </button>
            <button type="button" class="control" onclick={() => (open = null)}>Cancel</button>
          </div>
        {/if}
      </li>
    {/each}
  </ul>
</section>

<style>
  li.slip {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 10px;
    flex-wrap: wrap;
    padding: 7px 0;
    border-bottom: 1px dotted var(--rule-2);
    margin: 0;
  }
  li.slip.refused {
    color: var(--muted);
  }
  .slip .k {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  .slip .k .stamp {
    font-variant: normal;
    margin-left: 8px;
    vertical-align: 2px;
  }
  .slip .p {
    font-family: var(--mono);
    font-size: 11.5px;
    margin-left: auto;
  }
  .slip .refusal {
    font-size: 12.5px;
    color: var(--redline);
    flex-basis: 100%;
  }

  /* The same mark the countersignature block's control makes, because they are
     the two ends of one instrument and a student reads them as one object. */
  .control {
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 5px 12px;
    border: 1px solid var(--rule-2);
    background: none;
    color: var(--ink);
    cursor: pointer;
  }
  .control:hover {
    background: var(--paper-2);
  }
  .control[aria-disabled="true"] {
    color: var(--muted);
    cursor: not-allowed;
  }
  .control[aria-disabled="true"]:hover {
    background: none;
  }

  /* The stub is pinned to the line it belongs to: a confirmation that floated
     free of its Action would be the dialog by another name. */
  .stub {
    flex-basis: 100%;
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
    margin-top: 6px;
    padding: 9px 12px;
    background: var(--paper-2);
    border-left: 3px solid var(--ink);
  }
  .stub .terms {
    font-family: var(--mono);
    font-size: 11.5px;
    margin: 0;
    margin-right: auto;
  }
  .stub .confirm {
    border-color: var(--ink);
  }
</style>
