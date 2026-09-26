<!--
  A piece of text that may hold a term of art's first contact. `at` names the
  site, and `gloss_anchors.en.yml` says which words in it are anchored; with no
  anchor here, or outside a page that provides a glossary, this prints the text
  and nothing else. See `lib/gloss.svelte.js`.
-->
<script>
  import GlossWord from "./GlossWord.svelte"
  import { useGlossary, split } from "../../lib/gloss.svelte.js"

  let { at, text } = $props()

  const glossary = useGlossary()

  const parts = $derived(split(text ?? "", glossary?.anchorsAt(at) ?? []))
</script>

{#each parts as part}{#if part.term}<GlossWord term={part.term} rank={part.rank} word={part.word} />{:else}{part.text}{/if}{/each}
