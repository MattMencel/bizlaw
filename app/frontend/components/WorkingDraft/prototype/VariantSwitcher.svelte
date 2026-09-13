<!--
  PROTOTYPE — the switcher for #373's term sheet variants.

  `?variant=A|B|C` on the demo route, so a variant is shareable and survives a
  reload. It is read and written client-side: nothing in Ruby knows about it,
  which is what keeps this branch a diff against one page and three throwaway
  components.

  Deliberately loud and unlike the register — it must not read as part of the
  paper being judged. It is also gated on `import.meta.env.DEV`, so a stray
  merge cannot ship the bar.
-->
<script>
  let { variants, current, onpick } = $props()

  const cycle = (step) => {
    const at = variants.findIndex((v) => v.key === current)
    onpick(variants[(at + step + variants.length) % variants.length].key)
  }

  const onkeydown = (event) => {
    const el = document.activeElement
    if (el && (el.matches("input, textarea") || el.isContentEditable)) return
    if (event.key === "ArrowLeft") cycle(-1)
    if (event.key === "ArrowRight") cycle(1)
  }

  const name = $derived(variants.find((v) => v.key === current)?.name ?? "")
</script>

<svelte:window {onkeydown} />

<div class="bar">
  <button type="button" onclick={() => cycle(-1)} aria-label="Previous variant">←</button>
  <span class="label">{current} — {name}</span>
  <button type="button" onclick={() => cycle(1)} aria-label="Next variant">→</button>
  <span class="hint">#373 · ← → to cycle</span>
</div>

<style>
  .bar {
    position: fixed;
    bottom: 16px;
    left: 50%;
    transform: translateX(-50%);
    z-index: 50;
    display: flex;
    align-items: center;
    gap: 10px;
    background: #101010;
    color: #f2f2f2;
    border: 1px solid #3d3d3d;
    border-radius: 999px;
    padding: 7px 14px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.45);
    font-family: var(--mono);
    font-size: 12px;
  }
  button {
    background: #262626;
    color: #f2f2f2;
    border: 0;
    border-radius: 999px;
    width: 26px;
    height: 26px;
    cursor: pointer;
    font-size: 13px;
    line-height: 1;
  }
  button:hover {
    background: #3d3d3d;
  }
  .label {
    min-width: 250px;
    text-align: center;
    letter-spacing: 0.04em;
  }
  .hint {
    color: #8b8b8b;
    border-left: 1px solid #3d3d3d;
    padding-left: 10px;
    letter-spacing: 0.04em;
  }
</style>
