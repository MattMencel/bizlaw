<!--
  The Morning Briefing, as front matter on the draft rather than as a room or a
  dialog: #315 settled that it is scrolled past, not dismissed, which is why
  nothing here is collapsible and nothing remembers having been read.
-->
<script>
  let { front_matter, day } = $props()
</script>

<section aria-labelledby="front-matter">
  <h2 class="doc-sub" id="front-matter">Front matter · the morning of Day {day}</h2>

  <h3 class="doc-sub">Landed today</h3>
  {#if front_matter.landed.length}
    <ul class="plain">
      {#each front_matter.landed as doc (doc.identifier)}
        <li>{doc.title}</li>
      {/each}
    </ul>
  {:else}
    <p class="muted small">Nothing you bought has come back yet.</p>
  {/if}

  <h3 class="doc-sub">Served on you</h3>
  {#if front_matter.served.length}
    <ul class="plain">
      {#each front_matter.served as doc (doc.identifier)}
        <li>{doc.title} <span class="stamp warn">Served</span></li>
      {/each}
    </ul>
  {:else}
    <p class="muted small">The other Side has put nothing in front of you.</p>
  {/if}

  <h3 class="doc-sub">What you started with</h3>
  <ul class="plain">
    {#each front_matter.what_you_start_with as doc (doc.identifier)}
      <li>{doc.title}</li>
    {/each}
  </ul>

  <hr class="rule" />
  <h3 class="doc-sub">She said, on the day you sat down</h3>
  <div class="prose">
    {#each front_matter.opening_statement.split("\n\n") as para}
      <p>{para}</p>
    {/each}
  </div>

  <hr class="rule" />
  <h3 class="doc-sub">The calendar</h3>
  <ol class="calendar">
    {#each front_matter.calendar as d (d.ordinal)}
      <li class:closed={d.closed} class:today={d.today}>
        <span class="sr-only">
          Day {d.ordinal}, {d.in_fiction_date}{d.today ? ", today" : d.closed ? ", closed" : ""}
        </span>
        <span aria-hidden="true">{d.ordinal}</span>
      </li>
    {/each}
  </ol>
  <p class="tiny muted">
    {front_matter.calendar.length} Days, {front_matter.calendar[0].in_fiction_date} to
    {front_matter.calendar[front_matter.calendar.length - 1].in_fiction_date}. An Action's lead time
    is only plannable against how many are left.
  </p>

  <h3 class="doc-sub">How you are graded</h3>
  <p class="small">{front_matter.rubric.dimensions.join(" · ")}. {front_matter.rubric.bonus}</p>

  <hr class="rule" />
  <p class="small">{front_matter.grammar}</p>
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
