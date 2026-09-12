<!--
  The countersignature block, permanently under the term sheet — present before
  there is anything to sign, because an empty signature line is how the Day
  teaches that a commit needs a second hand. The control renders and is dead:
  the acts are their own tickets.
-->
<script>
  let { countersignature } = $props()
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
    <button type="button" class="execute" disabled>Execute this draft</button>
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
  .execute {
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 7px 14px;
    border: 1px solid var(--rule-2);
    background: none;
    color: var(--muted);
  }
  .execute[disabled] {
    cursor: not-allowed;
  }
</style>
