<!--
  Four hands in two blocks — the record of the whole game.

  An Acceptance *is* a countersignature on the other Side's instrument, which is
  why the two blocks have the same shape: the Side that drew the paper signed it
  by committing, the Side that took it signed by accepting, and each of those
  acts carried a teammate's confirmation or the Instructor's release of it.

  So this is where the Second is finally legible in both of its states at once.
  On the demo's own run the plaintiff's line reads *countersignature waived by
  the instructor* — one member, nobody to sign — and the defendant's names a
  teammate who actually signed. The rule the map spent two tickets teaching, on
  one page, as a record rather than as a lesson.

  **A waived line says so.** Leaving it blank would read as one nobody got round
  to, and `committed_offers.seconded_by` being null is a fact about how the act
  landed rather than a gap in the paper: a waiver *substitutes* for the Second,
  so there is no seconder of record and never will be.

  Unlike the working block there is no control here and no dashed line. Nothing
  on this instrument is waiting for a hand.
-->
<script>
  let { copy, signatures } = $props()

</script>

<section aria-labelledby="signatures">
  <h2 class="doc-sub" id="signatures" tabindex="-1">{copy.heading}</h2>

  <div class="parties">
    {#each signatures as party (party.role)}
      <div class="party">
        <div class="cap for">{party.for}</div>
        <div class="sig">
          <div class="line"><span class="hand">{party.signed_by}</span></div>
          <div class="cap">{copy.signed_by}</div>
        </div>
        <div class="sig">
          {#if party.waived}
            <!-- No line at all where nobody signed. A ruled line under a
                 waiver would be an empty signature block on an executed
                 instrument, which is the one thing this page cannot say. -->
            <div class="cap waived">{copy.waived}</div>
          {:else}
            <div class="line"><span class="hand">{party.seconded_by}</span></div>
            <div class="cap">{copy.countersigned_by}</div>
          {/if}
        </div>
      </div>
    {/each}
  </div>
</section>

<style>
  .parties {
    display: flex;
    gap: 34px;
    flex-wrap: wrap;
    /* The party caption is mono and uppercase like the section heading above
       it, so without this the two read as one block of small caps rather than
       as a heading over two signature blocks. */
    margin-top: 6px;
  }
  .party {
    flex: 1 1 240px;
    min-width: 0;
  }
  .sig {
    margin-top: 14px;
  }
  .sig .line {
    border-bottom: 1px solid var(--ink);
    height: 26px;
  }
  .sig .hand {
    font-family: "Snell Roundhand", "Apple Chancery", cursive;
    font-size: 20px;
    padding-left: 4px;
    line-height: 26px;
  }
  .cap {
    font-family: var(--mono);
    font-size: 10px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 0.07em;
    padding-top: 4px;
  }
  .cap.for {
    color: var(--ink);
    padding-top: 0;
    padding-bottom: 2px;
    border-bottom: 1px solid var(--rule-2);
  }
  /* A waiver occupies the height a signature line would, so the two parties'
     blocks stay level against each other. */
  .cap.waived {
    padding-top: 30px;
  }
</style>
