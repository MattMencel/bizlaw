<!--
  What the Client said, on the Day they were asked.

  The Consult is the one Action that buys words rather than paper, so there is
  no Case File row for it and this is the whole of where it lands. It sits under
  the countersignature block and above the slip: the slip is what bought it, and
  a reader who has just pressed Spend reads upward into the answer.

  **The face is printed once.** It is the only portrait in the game (ADR 0005),
  it belongs to the newest Consult — whose expression is the band that stands
  now — and the earlier lines are the same face saying something else earlier.
  The SVG arrives composed, from `WorkingDraft`: the two inks resolve through
  custom properties on an ancestor, so the portrait has to be *in* this document
  rather than behind an `<img>` that cannot see the paper it lies on.

  It is `aria-hidden` in the compositor's own markup, which is the call ADR 0008
  left to the first screen that drew a face. The Client's beat is emphasis and
  never the sole carrier: the band is printed as text beside the face and the
  words are the memo, so there is nothing truthful for alt text to add that the
  page does not already say. `{@html}` is safe here for the reason it usually is
  not — the string is built by `Portraits::Compose` out of committed SVG and an
  authored seed, and no student prose reaches it.
-->
<script>
  let { memo } = $props()
</script>

<section aria-labelledby="memo">
  <!-- Focusable so the round trip can land a keyboard reader on the words they
       just bought rather than back on the button that bought them. #363 put
       focus on the control because a refusal is wired to it; a Consult is the
       first act whose whole product is further up the page. -->
  <h2 class="doc-sub" id="memo" tabindex="-1">Memo — your Client</h2>

  {#if memo.empty_state}
    <p class="empty-state">{memo.empty_state}</p>
  {:else}
    {#each memo.entries as entry, i}
      <div class="beat">
        {#if i === 0 && memo.portrait}
          <div class="face">{@html memo.portrait}</div>
        {/if}
        <div class="said">
          <p class="tiny muted reads">Reads <strong>{entry.band}</strong></p>
          <div class="prose small">
            {#each entry.line.split("\n\n") as para}
              <p>{para}</p>
            {/each}
          </div>
        </div>
      </div>
    {/each}
  {/if}
</section>

<style>
  .beat {
    display: flex;
    gap: 16px;
    align-items: flex-start;
  }
  /* Every beat after the newest is indented to where the newest one's words
     begin, so the stack reads as one memo added to rather than as a list of
     separate memos. The face is 78px wide inside a 4px frame, and the gap
     is 16. */
  .beat + .beat {
    margin-top: 14px;
    padding-top: 14px;
    padding-left: 102px;
    border-top: 1px solid var(--rule);
  }
  .face {
    flex: 0 0 auto;
    line-height: 0;
    border: 1px solid var(--rule-2);
    padding: 3px;
    background: var(--paper-2);
  }
  .said {
    flex: 1 1 auto;
    min-width: 0;
  }
  .reads {
    margin: 0 0 6px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
  }
  .reads strong {
    color: var(--ink);
  }
  .prose p:last-child {
    margin-bottom: 0;
  }
</style>
