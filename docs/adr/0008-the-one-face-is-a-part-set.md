---
status: accepted
---

# The one face is a part set, printed in two inks

[ADR 0005](0005-the-register-is-the-paper.md) cancelled the
[#267](https://github.com/MattMencel/bizlaw/issues/267) cast and kept exactly one
portrait: a Team's own Client, where the Client speaks and nowhere else.
[#316](https://github.com/MattMencel/bizlaw/issues/316) asks what that portrait
actually is and who draws it. The answer is a **part set** — independent brow
and mouth layers over a held face — **printed as a duotone halftone**,
composed in Ruby from committed SVG, with a Case supplying nothing but an opaque
seed.

The ticket framed this as a much smaller ask than #267 and asked whether the
layered pipeline still earns its place at two or three states. It does, but not
for the reason ADR 0001 bought it, and the arithmetic that decides it is not the
arithmetic the ticket had.

## What the ticket did not have

**The inventory is three, and it was already closed.** `firm` and `ready` are
derived from the Reaction Band by engine rule; a third is authored to the
settlement occasion and is invariant across terms, Side and who accepted
([ADR 0007](0007-the-settlement-beat-is-the-executed-instrument.md),
and `CONTEXT.md` under *Dialogue*). #316 listed the inventory as its first open
question and was blocked on
[#319](https://github.com/MattMencel/bizlaw/issues/319) to get it; #319 answered
it on the way past.

**"One face" is one face *per Team*, and the cost is per Case.** `Cases::Import`
refuses any Case that does not author exactly two Clients, one for each of
`Side::ROLES` (`app/services/cases/import.rb`). So an authored Case needs two
Clients in three states — **six drawings, for every Case ever written**. The
commission is not a line item paid once; it is a standing per-Case art
dependency in a pipeline whose authors are law professors writing YAML.

That is the number that decides the pipeline, and it inverts the ticket's
question. At three states the *expression* combinatorics ADR 0001 bought are
worth nothing — 1,872 combinations to render three. But what recurs per Case is
**identity**, and a seeded part set is exactly an identity generator. Dropping
the layering to commit three hand-drawn pictures would save nothing today and
would put an illustrator in the Case-authoring loop forever.

## Decision

**The engine ships a part set and a compositor; a Case ships a seed.** One pair
of eyes and one nose, fixed for everyone. Brows and mouth are the only groups the
**engine** ever selects — from the band at a Consult, and from the authored
settlement expression at a settlement, where there is no band to read. Everything
else is **identity**, drawn once by the Case's seed and never moving again: hair,
garment, glasses, facial hair, and the skull itself. The skull is an identity
group rather than a fixed geometry, and it has to be — see the duotone
consequence below.

**A part is authored against a tone level, never a colour.** Five levels — the
two inks themselves plus three screens between them — each resolving through a
CSS custom property on an ancestor element, so
the same part prints as a halftone screen or a flat wash without being redrawn
and the ink follows the page rather than being baked into the art.

**A Case authors an opaque `portrait_seed` and nothing else.** Named part choices
were considered and rejected: `hair: shortCurly` does not survive a reskin, and
surviving the reskin is the entire architecture. An author rerolls until they
like the face, which is how this already works everywhere it exists.

**Composition is Ruby over committed SVG. Node appears nowhere.** ADR 0001 said
avatars are "rendered to static SVG at build time and the output committed", to
keep Node out of the runtime. A per-Case seed breaks that literally — the build
cannot render a face for a Case it has never seen — and the honest repair is not
to move the render to import time, which is Node on a deployed instance and
exactly what the clause forbids. It is to notice that the compositor is three
layers of string concatenation. Committing the *parts* rather than the *renders*
satisfies ADR 0001's intent more completely than ADR 0001's own mechanism did:
there is no Node at build, none at import, and none at runtime. `@dicebear/core`
demotes from a dependency to a design-time tool for choosing and previewing a
set.

**The register is duotone halftone, not flat colour.** A full-colour bust on a
legal memo fights the register ADR 0005 chose, and it is the drawing
[#312](https://github.com/MattMencel/bizlaw/issues/312) feared when it said a
cartoon blob would have the audience reacting to the art. A screened portrait is
what a face looks like on a scanned personnel file, and the prototype's toggle is
the evidence: identical parts, identical layering, and flat reads as a sticker
pasted onto the page where the screen reads as printed on it.

**The expression shift is small and deliberate.** Brows and mouth; eyes held. The
Client's beat is "emphasis, never the sole carrier" (`CONTEXT.md`, *The Client's
beat*) — the band is always on the page in words too — so the face confirms copy
the reader already has rather than carrying a signal they must read blind. That
is a much cheaper drawing, and the rule that would have made it expensive died
with the room.

**Stock first, commission second, and the swap is a file swap.** An
avataaars-derived set under the treatment is available today, MIT, and is what
unblocks the screens. Note what has *not* been shown: the prototype's parts are
drawn to avataaars' arrangement rather than lifted from it, so whether Pablo
Stanley's actual geometry survives being screened is untested, and it is the
shipping default. Check it before the first screen, not after. It will not clear
#312's "not a cartoon blob" bar on its own —
avataaars has one nose, enormous eyes and a hairline that reads as a sticker, and
screening a cartoon yields a screened cartoon. The commission is a reskin against
the same part schema, and buying a *set* rather than three pictures is what makes
that a drop-in with no code change.

**The default set ships in this repo; a commissioned set does not.** The
avataaars-derived default ships in-tree so the open engine runs for anyone. It
does **not** become Apache-2.0 by being committed here: the parts are a
derivative of MIT-licensed art and stay MIT, and MIT's grant is conditional on
carrying its copyright and permission notice with them. The repo is Apache-2.0
and the parts sit inside it under their own terms — which is an ordinary
arrangement and a live obligation, not a formality, so the MIT text and the
"Copyright (c) 2017 Pablo Stanley, Fang-Pen Lin" line ship in a third-party
notices file alongside the art. Take the art from `fangpenlin/avataaars`, where
that grant actually exists, and not from avataaars.com, whose licence is a line
of marketing copy behind a certificate that expired in 2021
(`docs/design/avatar-systems.md`).

A commissioned set is proprietary and lives with the Cases, loaded from a
configurable part-set root — the same split the repo already draws between the
engine and its authored content.

## Considered options

**Three hand-drawn portraits, layering dropped.** The ticket's own suggestion, and
right on the arithmetic it had. It fails on the arithmetic it did not: three
becomes six per Case, and every future Case needs an illustrator before it can be
imported.

**Render at import time.** Keeps a generator and gets per-Case identity, at the
price of Node on a deployed instance running `Cases::Import`. This is the
prohibition in ADR 0001 with the word "build" swapped out, and it buys nothing
over composing in Ruby.

**Pre-render a fixed roster at build time and let a seed pick from it.** Keeps
ADR 0001 verbatim. It commits 3M files to serve M identities, caps the roster at
whatever was generated, and makes adding a Client a build-artifact change.

**A flat-colour bust.** Cheaper to draw and to reason about. It loses the
register, which is the thing ADR 0005 spent three mocks establishing.

**No face at all.** Already rejected in ADR 0005, on the pitch rather than the
play, and nothing here reopens it.

## Consequences

**A compositor takes the render size as an argument.** The prototype's sharpest
finding. A halftone screen is fixed in ink on paper: a portrait printed small
gets fewer dots across it, not smaller ones. SVG patterns are the opposite —
`userSpaceOnUse` resolves against the viewBox, so one shared screen shrinks with
the portrait, and at the 78px the memo serves the cells fall under two pixels and
the face collapses into a flat grey wash, losing exactly the register it was
drawn for. The pitch must be divided back out by the render scale, one screen per
size served. So the compositor cannot emit one size-agnostic file per state and
let CSS resize it, and every render size the game uses is a size the part set has
been looked at in.

**Duotone deletes the cheap identity axis, and the part set pays for it in
shape.** avataaars parameterises 7 skin tones and 10 hair colours over its 103
parts; two inks remove both, and what is left is drawn work. The prototype's
stand-in set has 320 combinations and its six roster seeds collide inside them —
two of the six compose to the same person, left visible in the page on purpose.
**Hair is therefore the group to buy deep.**

`docs/design/avatar-systems.md`'s Option A is 52 parts, sized for six characters
in eight states and splitting about evenly between expression and identity. Three
states collapse the expression half from about 26 parts to about 7. Holding the
identity half at 26 gives **33**, and that is a **floor rather than an estimate**:
the same duotone decision that collapses the expression half is what forbids
holding the identity half still. Where above 33 it lands is a drawing question and
is not settled here.

**The commission is still unpriced, and deliberately.**
`docs/design/avatar-systems.md` declines to give a day rate or a dollar figure
from a primary source, and nothing since has produced one. This ADR moves the
question from *how many characters* to *how deep one part set goes*; it does not
answer what that costs, who commissions it, or when. That stays the one line item
on [#312](https://github.com/MattMencel/bizlaw/issues/312) outside the Rails
build, and it is now the only part of #316 still open.

**Two Clients of one Case must not collide, and that is an import check.** It is
the only collision anyone can see — Teams in different Simulations never meet,
and a Team sees only its own Client — so it belongs in `Cases::Import` beside the
settlement-lines gate, not in a uniqueness property the seed cannot carry.

**Independent identity groups need independently salted hashes.** Slicing one
hash word with shifts is the obvious implementation and is wrong: across six
seeds the prototype drew the same hair three times and never drew glasses or
facial hair at all, because the shifted bits stay correlated.

**`case_clients` gains a column and `Cases::Import` a gate.** The table today
carries `role`, `bound_cents`, `opening_statement` and two settlement lines, and
no name, persona or portrait. A required, undefaulted `portrait_seed` is the
whole schema surface this ADR implies.

**The portrait looks like it wants to be `aria-hidden`,** and this ADR does not
decide that. It is emphasis and never the sole carrier, the band is always present
as text, and there is nothing truthful for alt text to add that the page does not
already say in words — so the expected answer is decorative. But #312 puts
accessibility with the first screen, behind Capybara and axe-core, and that is
where the call belongs; recorded here only so the question is not lost.

**ADR 0001's build-time-Node clause is spent, not merely narrowed.** It survives
for the offline dialogue rake task, which is a real build-time Node dependency.
For the art it described a mechanism that this decision replaces with a stricter
one. That is the second narrowing ADR 0001 has taken — ADR 0005 took the first,
on Inertia — and the question of whether the stack still fits a game made
entirely of documents is still open and still not reopened here.

The prototype is the primary source:
[`prototype/the-one-face`](https://github.com/MattMencel/bizlaw/tree/prototype/the-one-face),
`prototype/one-face/index.html`. It is built to falsify these claims rather than
to illustrate them, and two of them pushed back.
