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
  and the shape the rest follow. Everything else here still only renders — the
  Offer, the Second and the Day's close are their own tickets.
-->
<script>
  import FrontMatter from "../../components/WorkingDraft/FrontMatter.svelte"
  import TermSheet from "../../components/WorkingDraft/TermSheet.svelte"
  import Countersignature from "../../components/WorkingDraft/Countersignature.svelte"
  import ActionSlip from "../../components/WorkingDraft/ActionSlip.svelte"
  import BackOfFile from "../../components/WorkingDraft/BackOfFile.svelte"

  let { letterhead, front_matter, term_sheet, countersignature, slip, back, spend_path } =
    $props()

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
      <FrontMatter {front_matter} day={letterhead.day} />

      <hr class="rule heavy" />

      <TermSheet {term_sheet} {letterhead} {countersignature} />

      <hr class="rule" />

      <Countersignature {countersignature} />

      <hr class="rule" />

      <ActionSlip {slip} {spend_path} />
    {:else}
      <BackOfFile {back} />
    {/if}
  </article>
</main>

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
