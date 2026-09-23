<!-- PROTOTYPE — gloss placement (#399). Renders a sentence with `[[term|word]]`
     markers, so a composed string can carry a gloss site. -->
<script>
  import Gloss from "./Gloss.svelte"

  let { text } = $props()

  const parts = $derived(
    text.split(/(\[\[[^\]]+\]\])/).map((s) => {
      const m = s.match(/^\[\[(\w+)\|?([^\]]*)\]\]$/)
      return m ? { term: m[1], word: m[2] || m[1] } : { text: s }
    })
  )
</script>

{#each parts as p}{#if p.term}<Gloss term={p.term}>{p.word}</Gloss>{:else}{p.text}{/if}{/each}
