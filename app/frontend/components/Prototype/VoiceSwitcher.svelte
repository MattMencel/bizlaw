<!-- PROTOTYPE — voice prototype (#388), branch prototype/voice only. -->
<script>
  import { page, router } from "@inertiajs/svelte"

  const KEYS = ["o", "a", "b", "c"]
  const current = $derived(page.props.voice?.key ?? "o")
  const label = $derived(
    current === "o" ? "Original" : page.props.voice?.strings?.name ?? current
  )

  const go = (step) => {
    const next = KEYS[(KEYS.indexOf(current) + step + KEYS.length) % KEYS.length]
    const url = new URL(window.location.href)
    url.searchParams.set("voice", next)
    router.get(url.pathname + url.search, {}, { preserveScroll: true, replace: true })
  }

  const onKey = (e) => {
    if (e.target.closest("input, textarea, [contenteditable]")) return
    if (e.key === "ArrowLeft") go(-1)
    if (e.key === "ArrowRight") go(1)
  }
</script>

<svelte:window onkeydown={onKey} />

{#if import.meta.env.DEV}
  <div class="voice-switcher" role="toolbar" aria-label="Prototype voice switcher">
    <button type="button" onclick={() => go(-1)} aria-label="Previous voice">←</button>
    <span>{label}</span>
    <button type="button" onclick={() => go(1)} aria-label="Next voice">→</button>
  </div>
{/if}

<style>
  .voice-switcher {
    position: fixed; bottom: 16px; left: 50%; transform: translateX(-50%);
    z-index: 1000; display: flex; gap: 12px; align-items: center;
    padding: 8px 14px; border-radius: 999px;
    background: #111; color: #fff; font: 600 14px/1 system-ui, sans-serif;
    box-shadow: 0 4px 18px rgb(0 0 0 / 0.35);
  }
  .voice-switcher button {
    background: #333; color: #fff; border: 0; border-radius: 999px;
    width: 28px; height: 28px; cursor: pointer; font: inherit;
  }
</style>
