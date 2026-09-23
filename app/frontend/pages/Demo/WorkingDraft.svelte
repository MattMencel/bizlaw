<!--
  The Day, in the grammar #315 settled: the draft is the page, always.

  Front matter on top, the term sheet through the middle with the
  countersignature block beneath it, the Action slip along the foot, and the
  Case File and the Docket on the back of the same instrument — turned over
  rather than navigated to.

  The parts are components under `components/WorkingDraft/` and this file is the
  instrument they are printed on: the masthead, the rules between them, and the
  one piece of state the draft has. Each part carries the marks only it makes;
  the register they share is `styles/register.css`, loaded once by the
  entrypoint, because Svelte scopes styles per component and the paper is one
  system.

  The flip is component state and deliberately not in the URL. #315 carried "if
  he never turns the page, that is the finding" as the cost of this grammar, and
  a link that can be handed over already flipped would answer the question the
  demo was built to ask.

  The slip writes: buying an Action off the menu is the first act in the game
  and the shape the rest follow. The Consult memo is the first thing an act puts
  *on* the page. The draft writes too — the term sheet is the surface a position
  is drawn on and the clip rail is what rides it, both owned by `Draft`, because
  `Offers::Stage` replaces the Terms and the Exhibits as one position. And the
  countersignature block executes: the one act on this page that is gated rather
  than merely priced, and the one that can end the Day. Under it, once there is
  something across the table, is the other Side's own paper and the act that
  takes it — the only act on this instrument that ends the whole run, and the
  only one with no price at all.

  It also re-reads itself when you come back to it. The demo is three tabs on one
  laptop and the acts cross between them — see `lib/live.svelte.js` for why that
  is a focus listener and not a subscription. It is safe over the draft he is
  typing because the key below is what decides whether `Draft` remounts, and it
  is derived from what is on the *table* rather than from the whole prop tree.
-->
<script>
  import FrontMatter from "../../components/WorkingDraft/FrontMatter.svelte"
  import Draft from "../../components/WorkingDraft/Draft.svelte"
  import Countersignature from "../../components/WorkingDraft/Countersignature.svelte"
  import Acceptance from "../../components/WorkingDraft/Acceptance.svelte"
  import ConsultMemo from "../../components/WorkingDraft/ConsultMemo.svelte"
  import ActionSlip from "../../components/WorkingDraft/ActionSlip.svelte"
  import BackOfFile from "../../components/WorkingDraft/BackOfFile.svelte"
  import GlossApparatus from "../../components/Prototype/GlossApparatus.svelte"
  import GlossSwitcher from "../../components/Prototype/GlossSwitcher.svelte"
  import { rereadOnFocus } from "../../lib/live.svelte.js"

  let {
    letterhead,
    front_matter,
    term_sheet,
    clipped,
    countersignature,
    acceptance,
    memo,
    slip,
    back,
    spend_path,
    offer_path,
    commit_path,
    acceptance_path
  } = $props()

  rereadOnFocus()

  let face = $state("front")

  // What the server says is on the table, and which Day's table it is. `Draft`
  // seeds its pending position from these props and then holds edits locally, so
  // it is remounted whenever the answer changes — a staging that lands clears the
  // edits it landed, and one that is refused leaves them exactly where they were,
  // under the sentence saying why. Keying it here rather than reconciling inside
  // the component keeps that rule in one line instead of an effect that writes
  // what it reads.
  //
  // The Day is part of it because it is part of *which instrument this is*, and
  // the table alone cannot say so: two Days with no position on either are
  // identical by every other value here, so a re-read that crosses a Day boundary
  // would leave yesterday's typing sitting on today's sheet — under a letterhead
  // that has moved, still marked *not yet on the table* about a table that is no
  // longer the one it was typed against. That is the defect #365 removed in
  // another form: the position in two places, and the reader left to compare
  // them.
  const onTheTable = $derived(
    JSON.stringify([
      letterhead.day,
      term_sheet.tracks.map((track) => track.draft),
      term_sheet.note,
      term_sheet.writable,
      clipped.documents.map((doc) => doc.clipped)
    ])
  )

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
    <GlossApparatus at="gutter" />
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
      <GlossApparatus at="front" />
      <FrontMatter {front_matter} day={letterhead.day} />

      <hr class="rule heavy" />

      {#key onTheTable}
        <Draft
          {term_sheet}
          {clipped}
          {letterhead}
          {countersignature}
          {offer_path}
          day={letterhead.day}
        />
      {/key}

      <hr class="rule" />

      <Countersignature {countersignature} {commit_path} day={letterhead.day} />

      <!-- Their paper, under ours. It is absent until there is something across
           the table, which the cold open never has — see `Acceptance.svelte`. -->
      {#if acceptance}
        <hr class="rule" />

        <Acceptance {acceptance} {acceptance_path} day={letterhead.day} />
      {/if}

      <hr class="rule" />

      <ConsultMemo {memo} />

      <hr class="rule" />

      <ActionSlip {slip} {spend_path} day={letterhead.day} />

      <GlossApparatus at="foot" />
    {:else}
      <BackOfFile {back} />
    {/if}
  </article>
</main>

<GlossSwitcher />

<style>
  /* The desk the sheet lies on. It is the page's and not the register's: the
     register is the paper, and a surface to put paper down on is what this
     screen happens to need. */
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
</style>
