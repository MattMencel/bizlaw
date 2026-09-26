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

  After the round trip, focus goes to wherever the act's result can be read: the
  control for a refusal, which carries the sentence, and the memo for a Consult,
  whose result is words further up the draft. See `RESULT_ANCHOR`.

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

  let { slip, copy, spend_path, day } = $props()

  // Which Action's stub is open, and one at a time: the whole argument for
  // confirming in place was keeping the other five prices in view, and two open
  // stubs give back exactly what the dialog was rejected for.
  let open = $state(null)

  const toggle = (kind) => (open = open === kind ? null : kind)

  // Where an act's result is legible. A refusal is wired to the control by
  // `aria-describedby`, so that is where a refused spend reads; a Consult's
  // whole product is the memo further up the page, and a reader left on the
  // button is told nothing at all about what the Client said.
  //
  // One rule rather than two: #363 wrote it as "focus returns to the control"
  // when no act yet put anything on the page, and the Consult is the first that
  // does. An act with nowhere else to land keeps the control.
  const RESULT_ANCHOR = {consult_client: "memo"}

  // The round trip re-renders the whole draft, which on a page this long leaves
  // a keyboard reader at the top of the document with no account of what just
  // happened. Found by id rather than held as a binding, because the visit may
  // remount this component and a held node would be the old one — which is also
  // why the refusal is read off the *fresh* props rather than remembered across
  // the post.
  async function restoreFocus(kind) {
    await tick()
    const refused = slip.actions.find((a) => a.kind === kind)?.refused_just_now
    const anchor = (!refused && RESULT_ANCHOR[kind]) || `spend-${kind}`
    document.getElementById(anchor)?.focus()
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
  <h2 class="doc-sub" id="slip">{slip.heading}</h2>
  <ul class="plain">
    {#each slip.actions as action (action.kind)}
      <li class="slip" class:refused={!action.affordable}>
        <span class="k">
          {action.label}
          {#if action.refused_just_now}<span class="stamp warn">{copy.refused}</span>{/if}
        </span>
        <span class="p">{action.line}</span>

        <!-- Present and dead rather than absent, and `aria-disabled` rather
             than `disabled`: a disabled button leaves the tab order, and the
             sentence saying why this one cannot be bought is the thing a reader
             who cannot see the greyed line most needs to reach. -->
        <button
          type="button"
          class="control"
          id={`spend-${action.kind}`}
          aria-label={action.spend_label}
          aria-expanded={open === action.kind}
          aria-controls={open === action.kind ? `stub-${action.kind}` : undefined}
          aria-disabled={!action.affordable}
          aria-describedby={action.refusal ? `refusal-${action.kind}` : undefined}
          onclick={() => action.affordable && toggle(action.kind)}
        >
          {copy.spend}
        </button>

        {#if action.refusal}
          <span class="refusal" id={`refusal-${action.kind}`}>{action.refusal}</span>
        {/if}

        {#if open === action.kind}
          <div class="stub" id={`stub-${action.kind}`}>
            <p class="terms">{action.stub}</p>
            <button
              type="button"
              class="control confirm"
              aria-label={action.confirm_label}
              onclick={() => spend(action.kind)}
            >
              {copy.confirm}
            </button>
            <button type="button" class="control" onclick={() => (open = null)}>{copy.cancel}</button>
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
  /* The sentence breaks the Action's own line rather than sitting after the
     price: it is a whole clause and the line it would share is three columns
     wide. The colour and size are the register's — see `register.css`. */
  .slip .refusal {
    flex-basis: 100%;
  }

  /* The slip's own two: a stub inside a flex row of Actions has to break the
     line, and it sits on the slip's darker ground rather than the sheet's. The
     rest of the mark is the register's. */
  .stub {
    flex-basis: 100%;
    margin-top: 6px;
    background: var(--paper-2);
  }
</style>
