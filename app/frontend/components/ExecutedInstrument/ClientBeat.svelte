<!--
  The Client's last word, in the slot their first ones were in.

  A Client speaks on exactly two occasions — a Consult and the settlement — and
  this is the second. It sits where the Consult memo sits, under the signatures,
  at the size the memo's face is served at, because reading them as the same
  person is the whole point of the part set: a halftone screen is fixed in ink
  on the page, so a second size would be a second face.

  **No Reaction Band.** ADR 0007 is explicit and the reason is not consistency:
  *firm* and *ready* mean willing to keep holding out, which is moot the instant
  the instrument is executed, and ADR 0006's argument for charging Action Budget
  for a band is that it informs a decision. There is none left. A `ready` chip on
  an executed agreement would be a category error dressed as consistency — and a
  free read on how the deal landed.

  The expression is authored to the occasion and is **invariant**: the same face
  on every settlement regardless of the terms, the Side, or who accepted. A
  Client whose face fell at a bad deal would be the Settlement Quality leak
  arriving through the art instead of through the copy.

  The heading is not *Memo* — a memo is what a Consult buys, and nobody bought
  this.
-->
<script>
  let { copy, beat } = $props()
</script>

<section aria-labelledby="client-beat">
  <h2 class="doc-sub" id="client-beat">{copy.heading}</h2>

  <div class="beat">
    <div class="face">{@html beat.portrait}</div>
    <div class="said prose small">
      {#each beat.line.split("\n\n") as para}
        <p>{para}</p>
      {/each}
    </div>
  </div>
</section>

<style>
  .beat {
    display: flex;
    gap: 16px;
    align-items: flex-start;
  }
  .face {
    flex: 0 0 auto;
    line-height: 0;
    border: 1px solid var(--rule-2);
    padding: 3px;
    background: var(--paper-2);
  }
  .said {
    flex: 1 1 auto;
    min-width: 0;
  }
  .said p:last-child {
    margin-bottom: 0;
  }
</style>
