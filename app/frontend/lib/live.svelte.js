import { router } from "@inertiajs/svelte"

// The paper re-reads itself when you come back to it.
//
// The demo is played from three tabs on one laptop and the acts cross between
// them: the Instructor grants a waiver in one and the countersignature block
// comes alive in another; the player executes his draft and the other firm's
// copy has a new offer on it. Something has to carry that across, and the
// cheapest honest thing is the gesture the professor is already making —
// switching tabs.
//
// So this is deliberately not liveness. There is no timer, no cable and no
// subscription: a page that is not being looked at learns nothing, and one that
// is being looked at is current as of the moment it was looked at. That is what
// paper on a desk does, and it is the whole of what a demo on one laptop needs.
// Anything more would be a Node process or a poll loop bought for a beat that
// the tab switch already pays for.
//
// A whole-page reload rather than a partial one. `WorkingDraft` composes one
// prop tree and a waiver moves two parts of it at once — the block on the front
// and a `second_waived` line on the Docket on the back — so an `only:` list
// would have to name most of it, and would go quietly stale the first time
// something else moved.
//
// It does not cost the reader their work. `WorkingDraft.svelte` keys the draft
// on what is on the *table*, so a re-read that finds the table unchanged leaves
// the position he is typing exactly where it was; one that finds it changed is
// a draft that landed or a Day that ended under him, which is precisely when
// what he is typing has stopped being current.
export function rereadOnFocus() {
  $effect(() => {
    const reread = () => {
      if (document.visibilityState === "visible") {
        router.reload({ preserveScroll: true })
      }
    }

    window.addEventListener("focus", reread)
    document.addEventListener("visibilitychange", reread)

    return () => {
      window.removeEventListener("focus", reread)
      document.removeEventListener("visibilitychange", reread)
    }
  })
}
