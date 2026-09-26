<!--
  The Morning Briefing, as front matter on the draft rather than as a room or a
  dialog: #315 settled that it is scrolled past, not dismissed, which is why
  nothing here is collapsible and nothing remembers having been read.

  Every word on it comes down from `WorkingDraft`: the headings as `copy`, and
  the empty states, the calendar and the rubric as sentences already composed.
  The copy lives in `config/locales/draft.en.yml`.
-->
<script>
  import GlossList from "../Gloss/GlossList.svelte"
  import Glossed from "../Gloss/Glossed.svelte"

  let { front_matter, copy } = $props()
</script>

<section aria-labelledby="front-matter">
  <h2 class="doc-sub" id="front-matter">{front_matter.heading}</h2>

  <GlossList />

  <h3 class="doc-sub">{copy.landed}</h3>
  {#if front_matter.landed_empty_state}
    <p class="empty-state">{front_matter.landed_empty_state}</p>
  {:else}
    <ul class="plain">
      {#each front_matter.landed as doc (doc.identifier)}
        <li>{doc.title}</li>
      {/each}
    </ul>
  {/if}

  <h3 class="doc-sub"><Glossed at="front_matter.served" text={copy.served} /></h3>
  {#if front_matter.served_empty_state}
    <p class="empty-state"><Glossed at="morning_briefing.served_empty" text={front_matter.served_empty_state} /></p>
  {:else}
    <ul class="plain">
      {#each front_matter.served as doc (doc.identifier)}
        <li>{doc.title} <span class="stamp warn">{copy.served_stamp}</span></li>
      {/each}
    </ul>
  {/if}

  <h3 class="doc-sub">{copy.started_with}</h3>
  {#if front_matter.what_you_start_with_empty_state}
    <p class="empty-state">{front_matter.what_you_start_with_empty_state}</p>
  {:else}
    <ul class="plain">
      {#each front_matter.what_you_start_with as doc (doc.identifier)}
        <li>{doc.title}</li>
      {/each}
    </ul>
  {/if}

  <hr class="rule" />
  <!-- Neither a pronoun nor a role. This component renders for both Sides and
       the two Clients are different people, so a heading that guessed either
       would attribute one Client's opening statement to something the Case
       never authored — `case_clients` carries no name, and giving it one is
       authored-content work (#343) this surface does not need. -->
  <h3 class="doc-sub">{copy.client_said}</h3>
  <div class="prose">
    {#each front_matter.opening_statement.split("\n\n") as para}
      <p>{para}</p>
    {/each}
  </div>

  <hr class="rule" />
  <h3 class="doc-sub">{copy.calendar}</h3>
  <ol class="calendar">
    {#each front_matter.calendar as d (d.ordinal)}
      <li class:closed={d.closed} class:today={d.today}>
        <span class="sr-only">{d.label}</span>
        <span aria-hidden="true">{d.ordinal}</span>
      </li>
    {/each}
  </ol>
  <p class="tiny muted">{front_matter.calendar_span}</p>

  <h3 class="doc-sub">{copy.graded}</h3>
  <p class="small">{front_matter.rubric}</p>

  <hr class="rule" />
  <p class="small"><Glossed at="morning_briefing.grammar" text={front_matter.grammar} /></p>
</section>

<style>
  /* The Day numbers are the whole calendar: the date each one carries is read
     out to a screen reader and drawn nowhere, because a strip of boxes is the
     only form in which fourteen dates fit across a sheet. */
  .calendar {
    display: flex;
    gap: 6px;
    list-style: none;
    margin: 0;
    padding: 0;
  }
  .calendar li {
    font-family: var(--mono);
    font-size: 11px;
    width: 26px;
    height: 26px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid var(--rule-2);
    color: var(--muted);
  }
  .calendar li.closed {
    background: var(--rule);
    color: #3f3a30;
  }
  .calendar li.today {
    border: 2px solid var(--ink);
    color: var(--ink);
    font-weight: 700;
  }
</style>
