<!--
  The Day, in the grammar #315 settled: the draft is the page, always.

  Front matter on top, the term sheet through the middle with the
  countersignature block beneath it, the Action slip along the foot, and the
  Case File and the Docket on the back of the same instrument — turned over
  rather than navigated to.

  The flip is component state and deliberately not in the URL. #315 carried "if
  he never turns the page, that is the finding" as the cost of this grammar, and
  a link that can be handed over already flipped would answer the question the
  demo was built to ask.

  Every control here renders and none of them writes. The acts are their own
  ticket.
-->
<script>
  let { letterhead, front_matter, term_sheet, countersignature, slip, back } = $props()

  let face = $state("front")

  const role = (r) => r.charAt(0).toUpperCase() + r.slice(1)

  // Joined here rather than in the markup: a `{#if}` around the separator loses
  // the space in front of it, and the cold open has no member to name.
  const meta = $derived(
    [`Day ${letterhead.day}/${letterhead.of}`, letterhead.in_fiction_date, letterhead.you]
      .filter(Boolean)
      .join(" · ")
  )
</script>

<svelte:head>
  <title>{letterhead.matter} — Day {letterhead.day}</title>
</svelte:head>

<main class="desk">
  <article class="sheet">
    <header class="masthead">
      <div class="letterhead">
        <h1 class="firm">{role(letterhead.role)} · {letterhead.matter}</h1>
        <span class="meta">{meta}</span>
      </div>
      <div class="turn">
        <span class="tiny muted">
          {face === "back" ? "You are looking at the back of the file." : "You are looking at the draft."}
        </span>
        <button type="button" onclick={() => (face = face === "back" ? "front" : "back")}>
          {face === "back" ? "Turn back to the draft" : "Turn the page over"}
        </button>
      </div>
    </header>

    {#if face === "front"}
      <section aria-labelledby="front-matter">
        <h2 class="doc-sub" id="front-matter">Front matter · the morning of Day {letterhead.day}</h2>

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
          {front_matter.calendar[front_matter.calendar.length - 1].in_fiction_date}. An Action's lead
          time is only plannable against how many are left.
        </p>

        <h3 class="doc-sub">How you are graded</h3>
        <p class="small">{front_matter.rubric.dimensions.join(" · ")}. {front_matter.rubric.bonus}</p>

        <hr class="rule" />
        <p class="small">{front_matter.grammar}</p>
      </section>

      <hr class="rule heavy" />

      <section aria-labelledby="term-sheet">
        <h2 class="doc-title" id="term-sheet">Draft terms of settlement</h2>
        <p class="doc-sub">
          {letterhead.matter} · Day {letterhead.day}{#if countersignature.drawn_by}{" "}· drawn by
            {countersignature.drawn_by}{/if}
        </p>

        {#if term_sheet.empty_state}
          <p class="empty-state">{term_sheet.empty_state}</p>
        {:else}
          <table class="terms">
            <thead>
              <tr>
                <th scope="col">Term</th>
                <th scope="col">Ours</th>
                <th scope="col">Theirs</th>
                <th scope="col">What she asked for</th>
              </tr>
            </thead>
            <tbody>
              {#each term_sheet.tracks as track (track.term)}
                <tr>
                  <th scope="row" class="term">{track.label}</th>
                  <td>
                    {#if track.ours}
                      {track.ours.money ? track.ours.amount : "Included"}
                    {:else}
                      <span class="silent">silent</span>
                    {/if}
                  </td>
                  <td>
                    {#if track.theirs}
                      <span class="theirs">{track.theirs.money ? track.theirs.amount : "Included"}</span>
                    {:else}
                      <span class="silent">silent</span>
                    {/if}
                  </td>
                  <td class="asp">
                    {#if track.aspiration}
                      {track.aspiration.money ? track.aspiration.amount : "Asked for"}
                    {:else}
                      <span class="silent">—</span>
                    {/if}
                  </td>
                </tr>
              {/each}
            </tbody>
          </table>
        {/if}
        {#if term_sheet.note}
          <p class="small note">{term_sheet.note}</p>
        {/if}
      </section>

      <hr class="rule" />

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
            <div class="line blank"></div>
            <div class="cap">
              Countersigned by{#if countersignature.may_sign.length}: {countersignature.may_sign.join(", ")}{/if}
            </div>
          </div>
        </div>
        <button type="button" class="execute" disabled>Execute this draft</button>
      </section>

      <hr class="rule" />

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
    {:else}
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
    {/if}
  </article>
</main>

<style>
  /* The register, ported from the #315 prototype rather than re-derived: what
     was approved there was this paper, and redrawing it would land a different
     page than the one that was judged. Four values are darkened from the
     prototype's — muted, rule-2, redline and stamp — because the prototype was
     drawn to be looked at and this one has to pass axe. */
  :global(:root) {
    --paper: #f4f1e8;
    --paper-2: #ece7da;
    --ink: #1c1a17;
    --muted: #615b4e;
    --rule: #cfc7b4;
    --rule-2: #9d9280;
    --redline: #8e2619;
    --stamp: #2b435f;
    --serif: "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
    --mono: "SFMono-Regular", Menlo, Consolas, monospace;
  }
  :global(body) {
    margin: 0;
    background: #3a352c;
    color: var(--ink);
    font-family: var(--serif);
    font-size: 15px;
    line-height: 1.5;
  }

  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0 0 0 0);
    white-space: nowrap;
    border: 0;
  }

  .desk {
    min-height: 100vh;
    display: flex;
    justify-content: center;
    padding: 26px 20px 60px;
  }
  .sheet {
    background: var(--paper);
    box-shadow: 0 1px 0 var(--rule-2), 0 8px 24px rgba(0, 0, 0, 0.28);
    max-width: 860px;
    width: 100%;
    padding: 0 52px 30px;
  }

  .masthead {
    position: sticky;
    top: 0;
    background: var(--paper);
    padding-top: 22px;
    z-index: 3;
  }
  .letterhead {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
    border-bottom: 2px solid var(--ink);
    padding-bottom: 6px;
  }
  /* The matter is the page's one h1. It is styled as letterhead rather than as
     a heading, which is what the register wants; the level is for the reader
     who is not looking at it. */
  h1.firm {
    font-variant: small-caps;
    letter-spacing: 0.09em;
    font-size: 15px;
    font-weight: 400;
    margin: 0;
  }
  .meta {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
  }
  .turn {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    padding: 10px 0;
  }
  .turn button {
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    cursor: pointer;
    background: none;
    border: 1px solid var(--rule-2);
    border-radius: 2px;
    padding: 6px 12px;
    color: var(--ink);
  }
  .turn button:hover {
    background: var(--paper-2);
  }

  h2,
  h3 {
    font-weight: 600;
    margin: 0;
  }
  .doc-title {
    font-size: 19px;
    margin-bottom: 2px;
  }
  .doc-sub {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin: 16px 0 10px;
    font-weight: 400;
  }
  section {
    padding-bottom: 8px;
  }
  .prose p {
    margin: 0 0 10px;
  }
  .small {
    font-size: 13.5px;
  }
  .rule {
    border: 0;
    border-top: 1px solid var(--rule);
    margin: 18px 0;
  }
  .rule.heavy {
    border-top: 2px solid var(--ink);
  }
  .muted {
    color: var(--muted);
  }
  .tiny {
    font-family: var(--mono);
    font-size: 11px;
    letter-spacing: 0.04em;
  }
  ul.plain,
  ol.plain {
    list-style: none;
    margin: 0;
    padding: 0;
  }
  ul.plain li {
    margin-bottom: 4px;
  }
  .note {
    font-style: italic;
    color: var(--muted);
  }

  .stamp {
    display: inline-block;
    font-family: var(--mono);
    font-size: 10px;
    font-weight: 700;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    padding: 3px 7px;
    border: 2px solid var(--stamp);
    color: var(--stamp);
    transform: rotate(-2.5deg);
  }
  .stamp.warn {
    border-color: var(--redline);
    color: var(--redline);
  }
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

  table.terms {
    width: 100%;
    border-collapse: collapse;
    font-size: 14px;
  }
  table.terms th[scope="col"] {
    text-align: left;
    font-family: var(--mono);
    font-size: 10px;
    font-weight: 400;
    text-transform: uppercase;
    letter-spacing: 0.09em;
    color: var(--muted);
    border-bottom: 1px solid var(--ink);
    padding: 0 10px 5px 0;
  }
  table.terms td,
  table.terms th[scope="row"] {
    padding: 7px 10px 7px 0;
    border-bottom: 1px solid var(--rule);
    vertical-align: top;
    text-align: left;
    font-weight: 400;
  }
  .term {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  /* Redline is the register's mark for their position, and it is decoration
     only: the column header is what says whose it is, so nothing here depends
     on seeing the strike or the colour. */
  .theirs {
    color: var(--redline);
    text-decoration: line-through;
    text-decoration-color: rgba(142, 38, 25, 0.5);
  }
  .silent {
    color: var(--muted);
    font-style: italic;
  }
  .asp {
    font-family: var(--mono);
    font-size: 11px;
    color: var(--muted);
  }

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

  .empty-state {
    border: 1px dashed var(--rule-2);
    padding: 16px 18px;
    color: var(--muted);
    font-size: 14px;
    background: rgba(255, 255, 255, 0.35);
  }
</style>
