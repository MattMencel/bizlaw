<!--
  The Instructor's minute: the record of the one act they take inside a running
  Day.

  It is drawn on the same desk and the same sheet as the students' file, because
  #366 settled that the Instructor's paper is paper too — but it is *their*
  paper. They are not in the dispute, so the letterhead names the Section they
  run rather than the matter, and there is no term sheet, no half, no Client and
  nothing of a Team's to read beyond the one fact that says whether a waiver
  would do anything: a position on the table with nobody's countersignature under
  it.

  **No signature line.** The obvious drawing is the block this releases, with a
  line for the Instructor to sign — and it is exactly wrong. `CONTEXT.md` §
  Second: the Instructor never Seconds on a Team's behalf, because Attribution
  would then name someone who did not take the position. An instrument inviting
  them to sign would say the opposite in the loudest register available, so what
  a granted line carries instead is a minute — who granted it, and when.

  There is no confirmation on it. A waiver costs nothing and is quoted by
  nothing, which is why `Offers::WaiveSecond` sits beside `Days::Command` rather
  than inside it; a confirmation protects against an irreversible *charge*, and
  the irreversible act this enables is still the Team's own to confirm.

  It re-reads on focus like the registers do — the professor grants here, moves
  to the player's tab, and comes back.

  **Once the matter has settled it is one line.** There is no Day being played
  after an Acceptance — `Days::Close` opens nothing — so there is nothing to
  grant a waiver on and no position that could still be executed. Without that
  branch this page renders the first *unclosed* Day, which after a settlement is
  one `Simulations::Create` laid down and `Days::Open` never reached: the
  professor's own tab would print a live tomorrow with two empty ruled lines,
  asserting the game was still going one gesture after the ending.

  It stays the minute rather than becoming the instrument. The executed agreement
  is the Teams' paper, and this page has never read their file.
-->
<script>
  import { router } from "@inertiajs/svelte"
  import { voiced } from "../../lib/prototypeVoice.js"
  import VoiceSwitcher from "../../components/Prototype/VoiceSwitcher.svelte"
  import { rereadOnFocus } from "../../lib/live.svelte.js"

  let { letterhead, settled, lines, waiver_path } = $props()

  rereadOnFocus()

  const role = (r) => r.charAt(0).toUpperCase() + r.slice(1)

  const meta = $derived(
    [
      settled ? "Settled" : `Day ${letterhead.day}/${letterhead.of}`,
      settled ? settled.in_fiction_date : letterhead.in_fiction_date,
      letterhead.you
    ]
      .filter(Boolean)
      .join(" · ")
  )

  // Granted where a line already carries one, and the Day gone where the Day
  // has closed underneath the page. Both leave the line standing as a record
  // rather than removing it: a minute with a line missing is a minute of
  // something that did not happen.
  function grant(role) {
    router.post(waiver_path, { role, day: letterhead.day }, { preserveScroll: true })
  }

  const granted = (at) =>
    new Date(at).toLocaleString(undefined, {
      hour: "numeric",
      minute: "2-digit",
      month: "short",
      day: "numeric"
    })
</script>

<svelte:head>
  <title>{settled ? "Minute — settled" : `Minute — Day ${letterhead.day}`}</title>
</svelte:head>

<main class="desk">
  <article class="sheet">
    <header class="masthead">
      <div class="letterhead">
        <h1 class="firm">{letterhead.section}</h1>
        <span class="meta">{meta}</span>
      </div>
    </header>

    <h2 class="doc-title">Minute of the instructor</h2>
    <p class="small muted matter">
      {#if settled}
        {letterhead.matter} · settled on Day {settled.day}
      {:else}
        {letterhead.matter} · Day {letterhead.day} of {letterhead.of}{letterhead.closed
          ? " · this Day has closed"
          : ""}
      {/if}
    </p>

    <hr class="rule heavy" />

    {#if settled}
      <!-- One line, and no controls. Their powers over this run are spent: a
           waiver releases the gate on executing a draft, and there is no Day
           left for one to be drawn on. -->
      <section aria-labelledby="closed">
        <h3 class="doc-sub" id="closed">The matter is closed</h3>
        <p class="small">
          The two Sides settled on Day {settled.day}, {settled.in_fiction_date}. No
          further Day opens, and there is nothing left to release.
        </p>
      </section>
    {:else}
      <section aria-labelledby="waivers">
        <h3 class="doc-sub" id="waivers">Waiver of the second</h3>
        <p class="small muted rubric">
          {voiced("minute_waiver", "A team whose other members are absent can draw an offer it cannot execute. Releasing the second lets that team execute alone, for this Day only. It is granted, never exercised — nobody countersigns on a team's behalf — and it cannot be taken back.")}
        </p>

        <ul class="plain">
          {#each lines as line (line.role)}
            <li class="minute" class:settled={!!line.granted}>
              <span class="k">{role(line.role)}</span>
              <span class="p">
                {line.drawn
                  ? "a position is on the table, unexecuted"
                  : "nothing drawn on the table"}
              </span>

              {#if line.granted}
                <p class="record">
                  The second is waived for this Day. Granted by {line.granted.by},
                  {granted(line.granted.at)}.
                </p>
              {:else}
                <button
                  type="button"
                  class="control"
                  id={`waive-${line.role}`}
                  aria-label={`Waive the second for the ${line.role}`}
                  aria-disabled={letterhead.closed}
                  aria-describedby={line.refusal ? `waiver-refusal-${line.role}` : undefined}
                  onclick={() => !letterhead.closed && grant(line.role)}
                >
                  Waive the second
                </button>
              {/if}

              {#if line.refusal}
                <span class="refusal" id={`waiver-refusal-${line.role}`}>{line.refusal}</span>
              {/if}
            </li>
          {/each}
        </ul>
      </section>
    {/if}
  </article>
</main>

<VoiceSwitcher />

<style>
  /* The same desk the file lies on. The Instructor's paper is paper. */
  .desk {
    min-height: 100vh;
    background: #3a352c;
    display: flex;
    justify-content: center;
    padding: 26px 20px 60px;
  }
  .sheet {
    background: var(--paper);
    box-shadow: 0 1px 0 var(--rule-2), 0 8px 24px rgba(0, 0, 0, 0.28);
    max-width: 700px;
    width: 100%;
    padding: 0 52px 30px;
  }
  .masthead {
    padding-top: 22px;
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
  .matter {
    margin: 2px 0 0;
  }
  .rubric {
    margin: 0 0 14px;
    max-width: 52ch;
  }

  /* One ruled line per Side, and it rules like the slip's does — this is the
     same paper, and a reader who has seen one list on it should not have to
     learn a second. */
  li.minute {
    display: flex;
    align-items: baseline;
    gap: 10px;
    flex-wrap: wrap;
    padding: 9px 0;
    border-bottom: 1px dotted var(--rule-2);
    margin: 0;
  }
  .minute .k {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  .minute .p {
    font-family: var(--mono);
    font-size: 11.5px;
    color: var(--muted);
    margin-left: auto;
    margin-right: 10px;
  }
  /* A granted line is a record, so it stops reading as something waiting to be
     done — but it stays on the minute, because that is what a minute is. */
  li.minute.settled .k {
    color: var(--muted);
  }
  .minute .record {
    flex-basis: 100%;
    font-size: 13.5px;
    margin: 4px 0 0;
  }
  .minute .refusal {
    flex-basis: 100%;
    font-size: 12.5px;
    color: var(--redline);
  }
</style>
