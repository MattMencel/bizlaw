<!--
  "Words used in this file": every term this face glosses, in the order it is
  met. It is one list with two layouts rather than a list and a set of notes,
  so each gloss has one element for its word to point at.

  On a sheet wide enough to carry a margin, each entry is lifted out of the list
  into the left margin, level with the word it glosses, and reads "term — gloss".
  The left margin because the term sheet's right one is the Client's. An entry
  that would overlap the one above it is pushed down beneath it.

  It sits at the top of the face it glosses, and the page it is on provides the
  glossary (`lib/gloss.svelte.js`).
-->
<script>
  import { tick } from "svelte"
  import { useGlossary } from "../../lib/gloss.svelte.js"

  let { level = 3 } = $props()

  const glossary = useGlossary()

  const entries = $derived(glossary?.glossed ?? [])

  let list = $state()
  let tops = $state({})

  // Level with the word, measured from the list's own top: the list is what an
  // entry is positioned against. The gap is the register's ruled-line rhythm.
  async function layout() {
    await tick()
    if (!list) return
    const origin = list.getBoundingClientRect().top
    let floor = -Infinity
    const next = {}
    const wanted = entries
      .map((entry) => ({ term: entry.term, want: entry.el.getBoundingClientRect().top - origin }))
      .sort((a, b) => a.want - b.want)
    for (const { term, want } of wanted) {
      const top = Math.max(want, floor)
      next[term] = `${top}px`
      floor = top + (document.getElementById(`gloss-${term}`)?.offsetHeight ?? 0) + 6
    }
    tops = next
  }

  // Anything that moves a word moves its note: a stub opening, a memo landing,
  // the window narrowing. All of them change the size of the page.
  $effect(() => {
    entries
    layout()
    const watch = new ResizeObserver(layout)
    watch.observe(document.body)
    return () => watch.disconnect()
  })
</script>

{#if entries.length}
  <div class="gloss-words">
    <svelte:element this={`h${level}`} class="doc-sub words-heading" id="words-used"
      >{glossary.heading}</svelte:element
    >
    <dl bind:this={list}>
      {#each entries as entry (entry.term)}
        <div class="entry" id={`gloss-${entry.term}`} style:top={tops[entry.term]}>
          <dt>{entry.label}<span aria-hidden="true">{" — "}</span></dt>
          <dd id={`gloss-${entry.term}-says`}>{entry.gloss}</dd>
        </div>
      {/each}
    </dl>
  </div>
{/if}

<style>
  /* Where there is no margin, the list itself: one line per term, above the
     rest of the face. */
  .gloss-words {
    margin-bottom: 14px;
  }
  dl {
    margin: 0;
    font-size: 13.5px;
  }
  .entry {
    margin-bottom: 2px;
    scroll-margin-top: 108px;
  }
  dt,
  dd {
    display: inline;
    margin: 0;
  }
  dt {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  dd {
    color: var(--muted);
  }

  /* A sheet wide enough grows a left margin, and each entry is lifted out of
     the list into it, level with its word. The sheet is reached from here
     rather than set on each page because a sheet has a margin exactly when it
     has something to put in it; `article` outranks a page's scoped `.sheet`. */
  @media (min-width: 1100px) {
    :global(article.sheet:has(.gloss-words)) {
      max-width: 1044px;
      padding-left: 236px;
    }

    .gloss-words {
      margin: 0;
    }
    .words-heading {
      position: absolute;
      width: 1px;
      height: 1px;
      margin: -1px;
      overflow: hidden;
      clip: rect(0 0 0 0);
      white-space: nowrap;
    }
    dl {
      position: relative;
      height: 0;
    }
    .entry {
      position: absolute;
      left: -208px;
      width: 168px;
      margin: 0;
      font-size: 12px;
      line-height: 1.35;
      font-style: italic;
      border-left: 2px solid var(--rule-2);
      padding-left: 8px;
    }
    dt {
      font-style: normal;
    }
  }
</style>
