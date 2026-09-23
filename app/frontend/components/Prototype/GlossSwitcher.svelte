<!-- PROTOTYPE — gloss placement (#399), branch prototype/gloss-placement only. -->
<script>
  import { VARIANTS, variant } from "../../lib/prototypeGloss.svelte.js"

  const KEYS = Object.keys(VARIANTS)
  document.documentElement.dataset.gloss = variant

  // A full load rather than a router visit: the first-contact registry is
  // module state, and a fresh page is the honest reset.
  const go = (step) => {
    const next = KEYS[(KEYS.indexOf(variant) + step + KEYS.length) % KEYS.length]
    const url = new URL(window.location.href)
    url.searchParams.set("gloss", next)
    window.location.assign(url)
  }

  const onKey = (e) => {
    if (e.target.closest("input, textarea, [contenteditable]")) return
    if (e.key === "ArrowLeft") go(-1)
    if (e.key === "ArrowRight") go(1)
  }
</script>

<svelte:window onkeydown={onKey} />

{#if import.meta.env.DEV}
  <div class="gloss-switcher" role="toolbar" aria-label="Prototype gloss placement switcher">
    <button type="button" onclick={() => go(-1)} aria-label="Previous placement">←</button>
    <span>{VARIANTS[variant]}</span>
    <button type="button" onclick={() => go(1)} aria-label="Next placement">→</button>
  </div>
{/if}

<style>
  .gloss-switcher {
    position: fixed; bottom: 16px; left: 50%; transform: translateX(-50%);
    z-index: 1000; display: flex; gap: 12px; align-items: center;
    padding: 8px 14px; border-radius: 999px;
    background: #111; color: #fff; font: 600 14px/1 system-ui, sans-serif;
    box-shadow: 0 4px 18px rgb(0 0 0 / 0.35);
  }
  .gloss-switcher button {
    background: #333; color: #fff; border: 0; border-radius: 999px;
    width: 28px; height: 28px; cursor: pointer; font: inherit;
  }
</style>
