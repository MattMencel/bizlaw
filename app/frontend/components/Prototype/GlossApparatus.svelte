<!-- PROTOTYPE — gloss placement (#399), branch prototype/gloss-placement only.
     The page-level half of a placement: the gutter notes (B), the footnotes (C)
     or the definitions clause (D). `at` says which slot of the page this is. -->
<script>
  import { tick } from "svelte"
  import { GLOSSES, variant, claims } from "../../lib/prototypeGloss.svelte.js"

  let { at } = $props()

  const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1)

  // B: each note sits level with its word in the left gutter, pushed down if it
  // would overlap the one above.
  let placed = $state([])
  let gutter = $state()

  async function layout() {
    await tick()
    if (!gutter) return
    const sheet = gutter.offsetParent
    if (!sheet) return
    const top0 = sheet.getBoundingClientRect().top
    let floor = 0
    placed = claims.list
      .map((t) => {
        const el = document.querySelector(`[data-gloss-anchor="${t.term}"]`)
        return el && { ...t, want: el.getBoundingClientRect().top - top0 }
      })
      .filter(Boolean)
      .sort((x, y) => x.want - y.want)
      .map((t) => {
        const top = Math.max(t.want, floor)
        floor = top + 64
        return { ...t, top }
      })
  }

  $effect(() => {
    if (at !== "gutter" || variant !== "b") return
    claims.list.length
    layout()
    const ro = new ResizeObserver(layout)
    ro.observe(document.querySelector(".sheet"))
    return () => ro.disconnect()
  })
</script>

{#if at === "gutter" && variant === "b"}
  <div class="gutter" bind:this={gutter} aria-hidden="true">
    {#each placed as t (t.term)}
      <p class="margin-note" style:top={`${t.top}px`}>
        <span class="mn-term">{t.term}</span> — {GLOSSES[t.term]}
      </p>
    {/each}
  </div>
{:else if at === "foot" && variant === "c" && claims.list.length}
  <section class="notes" aria-labelledby="gloss-notes">
    <hr class="rule" />
    <h2 class="doc-sub" id="gloss-notes">Notes</h2>
    <ol class="plain">
      {#each claims.list as t (t.term)}
        <li id={`${t.id}-note`}>
          <sup>{t.n}</sup>
          <strong>{cap(t.term)}</strong>: {GLOSSES[t.term]}.
          <a href={`#${t.id}-ref`} aria-label="Back to the text">↩</a>
        </li>
      {/each}
    </ol>
  </section>
{:else if at === "front" && variant === "d"}
  <section id="definitions" aria-labelledby="gloss-defs" tabindex="-1">
    <h3 class="doc-sub" id="gloss-defs">Words used in this file</h3>
    <dl class="defs">
      {#each Object.entries(GLOSSES) as [term, gloss]}
        <div>
          <dt>{cap(term)}</dt>
          <dd>{gloss}.</dd>
        </div>
      {/each}
    </dl>
    <hr class="rule" />
  </section>
{/if}

<style>
  .gutter {
    position: absolute;
    top: 0;
    left: 14px;
    width: 150px;
    height: 100%;
    pointer-events: none;
  }
  .margin-note {
    position: absolute;
    margin: 0;
    font-size: 12px;
    line-height: 1.35;
    font-style: italic;
    color: var(--muted);
    border-left: 2px solid var(--rule-2);
    padding-left: 8px;
  }
  .mn-term {
    font-style: normal;
    font-variant: small-caps;
    color: var(--ink);
  }
  .notes ol li {
    font-size: 13px;
    margin-bottom: 4px;
  }
  .defs {
    display: grid;
    grid-template-columns: max-content 1fr;
    gap: 2px 14px;
    margin: 0 0 8px;
    font-size: 14px;
  }
  .defs div {
    display: contents;
  }
  .defs dt {
    font-variant: small-caps;
    letter-spacing: 0.04em;
  }
  .defs dd {
    margin: 0;
  }
  :global(:root[data-gloss="b"] .sheet) {
    position: relative;
    padding-left: 190px !important;
    max-width: 1000px !important;
  }
</style>
