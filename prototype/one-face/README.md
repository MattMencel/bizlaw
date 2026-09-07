# Prototype — the one face

Throwaway. Answers [#316](https://github.com/MattMencel/bizlaw/issues/316): what the one
surviving face looks like, and what draws it. Not production code — no tests, no
persistence, no build.

## Run it

Double-click `index.html`. No server, no build, no network, no npm.

The bar at the foot switches **Halftone / Flat** (or press `f`) and rerolls the identity.
`?ink=halftone|flat`, `?seed=<string>` and `?chrome=off` work from the URL when the file is
opened directly; they are inert inside an embedded preview pane, which serves the page from
a `data:` URL with no query string.

## What was already settled before this

The ticket's own first open item — the expression inventory — closed while this was blocked.
[ADR 0007](../../docs/adr/0007-the-settlement-beat-is-the-executed-instrument.md) and
`CONTEXT.md` (under *Dialogue*) fix it at **three**: `firm` and `ready` derived from the Reaction Band by
engine rule, plus one **settlement** expression authored to the occasion and invariant across
terms, Side and who accepted. There is no fourth and there is no per-variant face.

The thing the ticket did not say, and which reframes the cost: `Cases::Import` refuses any
Case that does not author exactly two Clients, one per `Side::ROLES`. "One face" is one face
*per Team*. Per Case it is two Clients in three states — **six drawings, recurring for every
Case ever authored**, not a single line item paid once.

## What this prototype is for

Four claims, each of which the page is built to break rather than to illustrate.

**1. Three states differ enough to read and little enough to stay one person.** Only the brows
and the mouth move; eyes, nose, jaw, hair, skull and garment are byte-identical across all
three. Shown large, then at the **78px the memo actually serves**, which is the size the claim
has to survive.

**2. Duotone halftone reads as stationery; flat colour reads as a cartoon.** The toggle is the
experiment. Flat is not a strawman — it is the same parts, same geometry, same layering, with
four tone levels resolved to washes instead of screens.

**3. One part set plus an opaque seed yields Clients a reader calls different people.** The
roster is six seeds through one set of parts.

**4. The composition is layered SVG and one CSS class, so a Ruby compositor is enough.** No
Node at build time, no Node at import, no package manager anywhere.

The parts are hand-drawn in the avataaars idiom and are deliberately crude. They are **not**
the commission and not stock avataaars. Judge the treatment and the layering; the
draughtsmanship is a stand-in.

## What it found

**The halftone screen is a property of the page, not of the artwork.** This is the finding
with teeth. On real stationery the dot pitch is fixed in ink on paper: a portrait printed
small gets *fewer* dots across it, not smaller ones. SVG patterns are the other way round —
`userSpaceOnUse` resolves against the viewBox, so one shared screen shrinks with the portrait.
The first build did exactly that, and at 78px the cells fell under two pixels and the whole
face collapsed into a flat grey wash — losing precisely the register the screen was chosen
for. The fix is to divide the pitch back out by the render scale, one set of screens per
size served. **The consequence for the build: a compositor takes the render size as an
argument.** It cannot emit one size-agnostic file per state and let CSS resize it.

**Duotone deletes the cheap identity axis, and the part set has to pay for it in shape.** Skin
tone and hair colour are where an ordinary avatar system gets most of its variety — avataaars
parameterises 7 skin tones and 10 hair colours over 103 parts. Two inks remove both. What is
left is shape, which is drawn work. The stand-in set here has 320 combinations and the six
roster seeds collide inside it: *Whitfield · plaintiff* and *Arrowmark · defendant* compose to
the same person. That is left in the page on purpose. Two Clients of the **same** Case are the
only pair anybody can ever see together — different Simulations never meet — so uniqueness is
an import-time check rather than a property a seed can carry. But it is the number the
commission has to be scoped against, and it says hair is the group to buy deep.

**Independent groups need independent hashes.** Slicing one FNV word with shifts looked
correct and was not: across the six roster seeds it drew the same hair three times and never
once drew glasses or facial hair, because the shifted bits stay correlated. Each group is
salted and hashed on its own.

## What it did not test

- **Stock avataaars under the treatment.** The parts here are drawn to the avataaars
  *arrangement*, not lifted from it; whether Pablo Stanley's actual geometry survives being
  screened is untested, and it is the thing to check before the default set ships.
- **Print and forced-colours.** A `<pattern>` fill should survive both better than a filter
  would, which is why it was chosen, but neither was exercised.
- **The 78px claim on a projector.** The accessibility constraint that decided ADR 0001 is
  about a classroom projector, and this was judged on a laptop panel.
