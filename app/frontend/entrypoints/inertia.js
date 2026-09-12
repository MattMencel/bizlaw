import { createInertiaApp } from '@inertiajs/svelte'

// The register the draft is printed in. Global rather than scoped because
// Svelte scopes a component's styles to its own markup, and the draft's five
// parts share one paper. See `styles/register.css`.
import '../styles/register.css'

createInertiaApp({
  pages: "../pages",

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" }
    },
  },
})
