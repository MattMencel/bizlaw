<!--
  The Action Board as a slip along the foot of the draft. Every Action on the
  authored menu is priced whether or not today will cover it, and a refusal is
  printed beside the one it refuses: what the Day will not buy is as much of the
  Day's shape as what it will.
-->
<script>
  let { slip } = $props()
</script>

<section aria-labelledby="slip">
  <h2 class="doc-sub" id="slip">
    Slip — what this Day will still buy ·
    {#each Object.entries(slip.remaining) as [half, r], i}{i ? " · " : ""}{r.left ?? "—"} {r.label}{/each}
  </h2>
  <ul class="plain">
    {#each slip.actions as action (action.kind)}
      <li class="slip" class:refused={!action.affordable}>
        <span class="k">{action.label}</span>
        <span class="p">
          {action.cost} {action.half_label} ·
          {action.lands_today ? "lands today" : `lands Day ${action.landing_day ?? "—"}`}
        </span>
        {#if action.refusal}<span class="refusal">{action.refusal}</span>{/if}
      </li>
    {/each}
  </ul>
</section>

<style>
  li.slip {
    display: flex;
    justify-content: space-between;
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
  .slip .p {
    font-family: var(--mono);
    font-size: 11.5px;
  }
  .slip .refusal {
    font-size: 12.5px;
    color: var(--redline);
    flex-basis: 100%;
  }
</style>
