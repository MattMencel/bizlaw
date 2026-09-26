<!--
  One occurrence of an anchored word. Every occurrence registers, and only the
  one the glossary names as carrier is marked: a dotted underline, a link to its
  entry in the list (which on a wide sheet *is* the margin note), and the gloss
  as its description, so a screen reader reaches the note from the word rather
  than only finding it beside it.
-->
<script>
  import { untrack } from "svelte"
  import { useGlossary } from "../../lib/gloss.svelte.js"

  let { term, rank, word } = $props()

  const glossary = useGlossary()

  let el = $state()

  // Registering reads the list it writes to, so it is untracked: this re-runs
  // when the site changes, not whenever any other site comes or goes.
  $effect(() => {
    const site = [term, rank, el]
    return untrack(() => glossary.add(...site))
  })

  const carries = $derived(!!el && glossary.carrier(term) === el)
</script>

<span bind:this={el}
  >{#if carries}<a class="glossed" href={`#gloss-${term}`} aria-describedby={`gloss-${term}-says`}
      >{word}</a
    >{:else}{word}{/if}</span
>

<style>
  /* The word keeps the ink and the case of whatever it sits in — a heading, a
     stamp, a price — and says only that it is glossed. */
  .glossed {
    color: inherit;
    text-decoration: underline dotted;
    text-decoration-thickness: 1px;
    text-underline-offset: 3px;
  }
  .glossed:hover {
    text-decoration-style: solid;
  }
</style>
