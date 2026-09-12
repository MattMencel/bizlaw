<!--
  The back of the same instrument: the Case File and the Docket, turned over
  rather than navigated to. #315 carried the cost of that gesture knowingly —
  if the page is never turned, that is the finding — so this is one component
  and not a second page.

  A served document is stamped and carries no Exhibit clip: `CaseFile` strips
  the Exhibit property off a served row on read, because a document a Team was
  shown is knowledge and never ammunition.
-->
<script>
  let { back } = $props()
</script>

<section aria-labelledby="back-of-file">
  <h2 class="doc-title" id="back-of-file">Back of the file</h2>
  <p class="doc-sub">What we know, and what we have done</p>

  <h3 class="doc-sub">The papers</h3>
  {#if back.case_file.empty_state}
    <p class="empty-state">{back.case_file.empty_state}</p>
  {:else}
    {#each back.case_file.documents as doc (doc.identifier)}
      <div class="paper">
        <div class="paper-head">
          <strong>{doc.title}</strong>
          {#if doc.served}<span class="stamp warn">Served</span>{/if}
          {#if doc.playable}<span class="tab-clip">Exhibit</span>{/if}
          {#if doc.spent}<span class="tab-clip spent">Exhibit played</span>{/if}
          {#if doc.at_the_open}<span class="tiny muted">In hand at the open</span>{/if}
          <span class="tiny muted">Day {doc.day}</span>
        </div>
        <div class="prose small">
          {#each doc.body.split("\n\n") as para}
            <p>{para}</p>
          {/each}
        </div>
      </div>
    {/each}
  {/if}

  <hr class="rule" />
  <h3 class="doc-sub">The docket</h3>
  {#if back.docket.empty_state}
    <p class="empty-state">{back.docket.empty_state}</p>
  {:else}
    <ul class="plain">
      {#each back.docket.entries as entry, i (entry.at + i)}
        <li class="docket-line">
          <span class="d">Day {entry.day ?? "—"}</span>
          <span>
            {entry.act_label}{#if entry.by}{" "}<span class="by">— {entry.by}</span>{/if}
            {#if entry.band}{" "}<span class="band">· the Client reads {entry.band}</span>{/if}
          </span>
          <span class="c">
            {#if entry.spend}
              {entry.cost} {entry.half_label} · lands Day {entry.lands_on_day}
            {:else}
              no cost
            {/if}
          </span>
        </li>
      {/each}
    </ul>
  {/if}
</section>

<style>
  .paper {
    margin-bottom: 18px;
  }
  .paper-head {
    display: flex;
    gap: 8px;
    align-items: baseline;
    flex-wrap: wrap;
    margin-bottom: 4px;
  }
  /* The clip is the mark for a document that can still be played as an
     Exhibit, and goes grey once it has been. */
  .tab-clip {
    display: inline-block;
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    background: #d8b24a;
    color: #3a2c05;
    padding: 2px 8px;
    border-radius: 0 3px 3px 0;
  }
  .tab-clip.spent {
    background: var(--rule);
    color: #3f3a30;
  }

  .docket-line {
    display: grid;
    grid-template-columns: 60px 1fr auto;
    gap: 10px;
    padding: 6px 0;
    border-bottom: 1px solid var(--rule);
    font-size: 13.5px;
    margin: 0;
  }
  .docket-line .d,
  .docket-line .c {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
  }
  .by,
  .band {
    font-style: italic;
    color: var(--muted);
  }
</style>
