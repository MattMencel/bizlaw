<!--
  What is clipped to the draft, down the side of the instrument — where
  `CONTEXT.md` § Register puts it. An Exhibit cannot be played alone: it rides a
  staged Offer, so this is not a hand to play from but a set of tabs attached to
  the position on the sheet beside it.

  It is on the **front**. The tab-clip mark also appears on the back, on the
  papers in the Case File, and that one is a property of a document — *this is
  ammunition* — while this one is an act. Putting the only Exhibit gesture on the
  back would hide it behind the one gesture #315 knowingly accepted might never
  be made.

  The rail is absent until this Team has ever held a playable Exhibit —
  `CaseFile#exhibits_available?`, the one thing on the whole surface that gates —
  and permanent afterwards. A spent Exhibit stays listed and struck: the document
  is not spent, and a row that vanished on being played would read as a paper
  lost rather than a card played.

  It costs nothing to clip one. What it costs is on the countersignature block,
  where executing the draft is priced as one figure over the Offer and every
  Exhibit riding it — so a half that will not cover all of it refuses the whole
  play rather than quietly dropping one.
-->
<script>
  import Glossed from "../Gloss/Glossed.svelte"
  let { copy, clipped, position } = $props()
</script>

<aside class="rail" aria-labelledby="clipped">
  <h2 class="doc-sub" id="clipped">{copy.heading}</h2>
  <ul class="plain">
    {#each clipped.documents as doc (doc.identifier)}
      <li class="clip" class:spent={doc.spent}>
        {#if doc.spent}
          <span class="tab-clip spent">{copy.played}</span>
          <span class="title struck">{doc.title}</span>
        {:else if clipped.writable}
          <label>
            <input type="checkbox" bind:checked={position.exhibits[doc.identifier]} />
            <span class="title">{doc.title}</span>
          </label>
        {:else}
          <span class="tab-clip"><Glossed at="clipped.exhibit" text={copy.exhibit} /></span>
          <span class="title">{doc.title}</span>
        {/if}
      </li>
    {/each}
  </ul>
  <p class="tiny muted foot"><Glossed at="clipped.foot" text={copy.foot} /></p>
</aside>

<style>
  /* Attached to the edge of the instrument rather than set on it: one rule down
     the left is the whole of the join, which is what a clip looks like. */
  .rail {
    border-left: 1px solid var(--rule);
    padding-left: 14px;
  }
  .rail .doc-sub {
    margin-top: 0;
  }
  .clip {
    margin-bottom: 9px;
    font-size: 13px;
    line-height: 1.35;
  }
  .clip label {
    display: flex;
    gap: 7px;
    align-items: start;
    cursor: pointer;
  }
  .clip input {
    margin: 3px 0 0;
    accent-color: var(--stamp);
  }
  .clip .title.struck {
    text-decoration: line-through;
    color: var(--muted);
  }
  /* The same clip the back of the file makes, because it is the same object. */
  .tab-clip {
    display: inline-block;
    font-family: var(--mono);
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    background: #d8b24a;
    color: #3a2c05;
    padding: 1px 6px;
    border-radius: 0 3px 3px 0;
    margin-right: 5px;
  }
  .tab-clip.spent {
    background: var(--rule);
    color: #3f3a30;
  }
  .foot {
    margin: 14px 0 0;
    line-height: 1.4;
  }
</style>
