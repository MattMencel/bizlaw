<!-- PROTOTYPE — gloss placement (#399), branch prototype/gloss-placement only.
     Wraps one occurrence of a term of art. The first site in reading order that
     may claim the term carries its gloss, in the form the variant places it. -->
<script>
  import { onDestroy } from "svelte"
  import { GLOSSES, variant, claim, release, numberOf } from "../../lib/prototypeGloss.svelte.js"

  let { term, kind = "prose", children } = $props()

  const token = claim(term, kind)
  onDestroy(() => release(token))
  const n = $derived(token ? numberOf(term) : null)
</script>

{#if !token}{@render children()}{:else if variant === "a"}<span class="g-word">{@render children()}</span
  ><span class="g-inline">{" "}({GLOSSES[term]})</span>{:else if variant === "b"}<span
    class="g-word g-anchor"
    data-gloss-anchor={term}>{@render children()}</span
  >{:else if variant === "c"}<span class="g-word" id={`${token.id}-ref`}>{@render children()}</span
  ><sup class="g-mark"><a href={`#${token.id}-note`} aria-label={`Note ${n}: ${term}`}>{n}</a></sup
  >{:else if variant === "d"}<a class="g-word g-defined" href="#definitions">{@render children()}</a>{/if}

<style>
  .g-word {
    text-decoration: underline dotted;
    text-underline-offset: 3px;
  }
  .g-inline {
    font-style: italic;
    color: var(--muted);
    text-transform: none;
    letter-spacing: 0;
  }
  .g-mark {
    font-size: 0.7em;
    line-height: 0;
  }
  .g-mark a {
    color: inherit;
  }
  .g-defined {
    color: inherit;
  }
</style>
