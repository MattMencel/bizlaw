<!--
  The page the file rests on, once the matter has settled.

  It is the same instrument with the same two faces, not a different document:
  the front has stopped being a draft, and the back still turns to the Case File
  and the Docket. That is what ADR 0007 means by the executed agreement becoming
  the page the file rests on, and it is why the turn control is still here.

  **Everything about a Day is gone.** No Morning Briefing, no Action slip, no
  Consult memo, no term sheet to write on — a settled run has no today. Nothing
  can be bought, drawn, executed or taken, so the slip along the foot is not
  rendered refusing six Actions; six refusals at the beat this map spent nine
  tickets reaching would be administrative noise over the ending.

  **It does not re-read on focus, and it is the only page in the demo that
  doesn't.** `rereadOnFocus` exists because acts cross between three tabs on one
  laptop; there are no acts left, on either Side, and the Docket on the back is
  closed. The tab that still needs the gesture is the *unsettled* one — the
  plaintiff's `WorkingDraft`, which has it, and which swaps to this page the
  moment he looks back at it after the defendant takes his offer. That is how a
  Team whose Offer was accepted finds out: no Day opens after a settlement, so
  there is no Morning Briefing to learn it from.

  It carries no endpoints. A control that cannot exist has nowhere it needs to
  post.
-->
<script>
  import ExecutedTerms from "../../components/ExecutedInstrument/ExecutedTerms.svelte"
  import Signatures from "../../components/ExecutedInstrument/Signatures.svelte"
  import ClientBeat from "../../components/ExecutedInstrument/ClientBeat.svelte"
  // The back of the instrument is the same surface on both faces of the game —
  // settling does not unknow anything — so this is the draft's own component
  // rather than a second copy of it.
  import BackOfFile from "../../components/WorkingDraft/BackOfFile.svelte"

  let { copy, letterhead, terms, signatures, stamp, beat, back } = $props()

  let face = $state("front")

  // No Day and no *of ten*. The clock has stopped, and an ordinal out of a
  // calendar nobody will reach again invites the reader to ask what happens
  // tomorrow — which is the dead end this page exists to not be. What dates the
  // instrument is the execution stamp on the sheet.
  const meta = $derived([copy.settled, letterhead.in_fiction_date, letterhead.you].join(" · "))
</script>

<svelte:head>
  <title>{letterhead.title}</title>
</svelte:head>

<main class="desk">
  <article class="sheet">
    <header class="masthead">
      <div class="letterhead">
        <h1 class="firm">{letterhead.role_label} · {letterhead.matter}</h1>
        <span class="meta">{meta}</span>
      </div>
      <div class="turn">
        <button type="button" onclick={() => (face = face === "back" ? "front" : "back")}>
          {face === "back" ? copy.turn.to_front : copy.turn.to_back}
        </button>
      </div>
    </header>

    {#if face === "front"}
      <hr class="rule heavy" />

      <ExecutedTerms copy={copy.terms} {terms} {stamp} />

      <hr class="rule" />

      <Signatures copy={copy.signatures} {signatures} />

      <hr class="rule" />

      <ClientBeat copy={copy.beat} {beat} />
    {:else}
      <BackOfFile {back} />
    {/if}
  </article>
</main>

<style>
  /* The same desk and the same sheet as the working draft. They are the page's
     rather than the register's — the register is the paper, and a surface to
     put paper down on is what a screen happens to need — so the two pages that
     need one each say so. */
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
    justify-content: flex-end;
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
