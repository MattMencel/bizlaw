<!--
  PROTOTYPE — variant C: the instrument itself, in numbered articles.

  The furthest end of the register. Every Term in the Case's vocabulary is an
  article of a draft agreement, and the position is the operative words at the
  end of the sentence: the other Side's struck through, ours written after it,
  and a ruled blank where nobody has written. The Client's aspiration is a note
  in the true margin, beside the article it belongs to.

  **It costs authored content, and that is the point of putting it up.** The
  engine knows a Term's key and nothing else — `WorkingDraft#label_for`
  humanizes it and says so. Every sentence below is invented here to see what
  the register would read like if a Term carried clause text, which is #343 and
  ruled out of this map. If C wins, it does not land as C: it lands as a ticket
  on the authored Case.

  A list of articles cannot be a table, so this answers #373's structural
  question from the other side: the four-way distinction the shipped `<thead>`
  carries has to be respoken inside each article as hidden text.

  The three silences:
    · nobody has tabled the Term   → the article stands with a blank slot
    · a Position carrying no figure → the annexed phrase, in ink or struck
    · the Client is indifferent     → the margin is empty
-->
<script>
  let { term_sheet, letterhead, countersignature } = $props()

  // Invented, per the note above. `sentence` carries one slot; `annexed` is
  // what fills it for a position that names no figure.
  const CLAUSES = {
    money: {
      sentence: ["The Respondent shall pay to the Claimant the sum of ", "."],
      annexed: "a sum to be agreed",
    },
    apology: {
      sentence: ["The Respondent shall deliver to the Claimant a written apology, ", "."],
      annexed: "in the form annexed",
    },
    nda: {
      sentence: ["The parties shall keep the terms of this agreement confidential, ", "."],
      annexed: "on the mutual terms annexed",
    },
    reinstatement: {
      sentence: ["The Respondent shall reinstate the Claimant to their former position, ", "."],
      annexed: "on the terms annexed",
    },
    training: {
      sentence: ["The Respondent shall provide supervisory training at the plant, ", "."],
      annexed: "to the programme annexed",
    },
    reference_letter: {
      sentence: ["The Respondent shall furnish the Claimant a letter of reference, ", "."],
      annexed: "in the form annexed",
    },
    policy_change: {
      sentence: ["The Respondent shall amend its reassignment policy, ", "."],
      annexed: "as set out in the schedule annexed",
    },
  }

  const clause = (track) =>
    CLAUSES[track.term] ?? {
      sentence: [`The parties agree as to ${track.label.toLowerCase()}, `, "."],
      annexed: "on the terms annexed",
    }

  const operative = (position, track) =>
    position.money ? position.amount : clause(track).annexed

  const margin = (aspiration) => (aspiration.money ? aspiration.amount : "wants it")
</script>

<section aria-labelledby="term-sheet">
  <div class="sheet-head">
    <h2 class="doc-title" id="term-sheet">Draft terms of settlement</h2>
    {#if term_sheet.ours_staged}
      <span class="draft-mark">Draft — not executed</span>
    {:else if countersignature.executed}
      <span class="draft-mark executed">Executed</span>
    {/if}
  </div>
  <p class="doc-sub">
    {letterhead.matter} · Day {letterhead.day}{#if countersignature.drawn_by}{" "}· drawn by
      {countersignature.drawn_by}{/if}
  </p>

  {#if term_sheet.empty_state}
    <p class="empty-state">{term_sheet.empty_state}</p>
  {:else}
    <p class="rubric">
      Struck through, their last committed offer. Written in, ours. The margin is the
      Client's.
    </p>

    <ol class="articles">
      {#each term_sheet.tracks as track (track.term)}
        {@const words = clause(track).sentence}
        <li>
          <span class="heading">{track.label}.</span>
          {words[0]}<!--
          -->{#if track.theirs}<s
              ><span class="sr-only">their last offer, struck: </span>{operative(
                track.theirs,
                track
              )}</s
            >{" "}{/if}<!--
          -->{#if track.ours}<span class="filled"
              ><span class="sr-only">ours: </span>{operative(track.ours, track)}</span
            >{:else}<span class="blank" aria-hidden="true"></span><span class="sr-only"
              >left blank</span
            >{/if}{words[1]}
          {#if track.aspiration}
            <span class="hand">
              <span class="sr-only">The Client asked for: </span>{margin(track.aspiration)}
            </span>
          {/if}
        </li>
      {/each}
    </ol>
  {/if}
  {#if term_sheet.note}
    <p class="small note">{term_sheet.note}</p>
  {/if}
</section>

<style>
  .sheet-head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    gap: 12px;
    flex-wrap: wrap;
  }
  .draft-mark {
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.16em;
    color: var(--redline);
    border: 1px solid var(--redline);
    padding: 2px 6px;
    text-transform: uppercase;
  }
  .draft-mark.executed {
    color: var(--stamp);
    border-color: var(--stamp);
  }
  .rubric {
    font-size: 12.5px;
    font-style: italic;
    color: var(--muted);
    margin: 0 0 16px;
  }

  ol.articles {
    margin: 0;
    padding-left: 22px;
    font-size: 15px;
  }
  /* The margin is absolute so the `<li>` stays a list item: `display: flex` or
     `grid` here would take the list semantics with it in some engines, and the
     numbering is the article number. */
  ol.articles li {
    position: relative;
    padding: 0 166px 11px 0;
    line-height: 1.55;
  }
  .heading {
    font-variant: small-caps;
    letter-spacing: 0.04em;
    font-weight: 600;
    margin-right: 3px;
  }

  s {
    color: var(--redline);
    text-decoration-color: rgba(142, 38, 25, 0.55);
  }
  .filled {
    border-bottom: 1px solid var(--rule-2);
    padding-bottom: 1px;
  }
  .blank {
    display: inline-block;
    border-bottom: 1px solid var(--rule-2);
    width: 168px;
    height: 1.05em;
    vertical-align: -0.2em;
  }
  .hand {
    position: absolute;
    top: 0;
    right: 0;
    width: 148px;
    padding-left: 18px;
    border-left: 1px solid var(--rule);
    font-family: var(--mono);
    font-size: 11px;
    line-height: 1.5;
    color: var(--muted);
  }
  .note {
    font-style: italic;
    color: var(--muted);
    margin-top: 14px;
  }
</style>
