# Avatar systems for expressive NPCs

Research for [#259](https://github.com/MattMencel/bizlaw/issues/259). Investigated 2026-08-28.

The question: which open-source avatar system can carry expressive NPC states for professional
adults in a boardroom, and what does the art pipeline look like on top of it?

## Bottom line

Use **avataaars** as the face and expression engine, rendered through **DiceBear's** `@dicebear/core`,
and commission a business-register part set on top of it.

avataaars is the only candidate I found where expression is compositional rather than a fixed menu.
It splits eyebrows (13), eyes (12), and mouth (12) into independent layers over a single fixed head
geometry, so 1,872 expression combinations come out of 37 drawn parts, and every one of them sits on
the same recognisable face. It is also the only library in the entire DiceBear corpus of 61 styles
that ships actual business attire: `blazerAndShirt`, `blazerAndSweater`, and `collarAndSweater`.

I tested this rather than assuming it. Pinning identity and composing eyebrow, eye, and mouth
variants produces states that read as pleased, wary, insulted, resigned, skeptical, shocked, and
dismissive on one unchanged character in a blazer. That is the exact mechanic the game needs.

Now the bad news. No library on the market gives you people seated at a conference table. Not one.
Every candidate is a front-facing bust cropped at the shoulders. Closing that gap is roughly a
**110 to 120 part** commission, which is the size of the entire avataaars library (103 parts) or
Open Peeps (104 parts). A bust-only version that skips the table is about **50 parts**. Details in
[Part-count estimate](#part-count-estimate).

## How I checked

Marketing pages lie about part counts, so I worked from the rendered assets instead.

DiceBear publishes a machine-readable definition per style at
`https://api.dicebear.com/10.x/<style>/definition.json`, containing the licence metadata and every
drawn variant as SVG path data. I pulled all 61 and counted components directly. I also downloaded
the Open Peeps sitting-pose PNGs from openpeeps.com's own CDN and looked at them, cloned
`fangpenlin/avataaars` to read its LICENSE and confirm where the artwork actually lives, and rendered
comparison grids through the live DiceBear API to judge the dress register by eye.

## The two gaps, by candidate

| Library | Licence | Expression | Business dress | Seated at table |
| --- | --- | --- | --- | --- |
| avataaars | MIT (see below) | Compositional. 13 brows x 12 eyes x 12 mouths | 3 of 9 garments | No |
| Open Peeps | CC0 1.0 | 30 fixed presets, one merged layer | None in the web port | No |
| Notionists | CC0 1.0 | 13 brows x 5 eyes x 30 mouths | ~2 of 25 garments | No |
| Humaaans | CC0 1.0 | None. Faces have no features | Yes | Standing/walking only |
| Big Ears | CC BY 4.0 | 32 eyes x 38 mouths | None | No |
| Personas | CC BY 4.0 | 6 eyes x 7 mouths | 4 garments, none business | No |
| Live2D | Proprietary | Full rigging | N/A | N/A |

Sources: [DiceBear style definitions](https://www.dicebear.com/styles/),
[openpeeps.com](https://www.openpeeps.com/), [humaaans.com](https://www.humaaans.com/),
[Live2D SDK licence](https://www.live2d.com/en/sdk/license/).

### avataaars

Component counts from
[the live definition](https://api.dicebear.com/10.x/avataaars/definition.json): `eyebrows` 13,
`eyes` 12, `mouth` 12, `nose` 1, `top` 34 (hair and hats), `clothes` 9, `facialHair` 5,
`accessories` 7, `clothesGraphic` 10. Total 103 drawn parts.

The head and face outline are not a component at all. They live in the definition's fixed canvas
elements, which is what makes every expression part reusable across every character. Colour is
parameterised properly: 7 skin tones, 10 hair colours, 14 clothing colours.

Named expression parts carry real emotional vocabulary. Eyebrows include `angry`, `sadConcerned`,
`raisedExcited`, `upDown`, `frownNatural`. Mouths include `concerned`, `serious`, `grimace`, `sad`,
`disbelief`, `twinkle`. Eyes include `squint`, `side`, `eyeRoll`, `closed`, `surprised`. You can
build a negotiation emotional range out of these without drawing anything.

The style is a front-facing bust on a 280x280 canvas. No arms, no hands, no lower body, no
orientation other than straight at the camera.

### Open Peeps

The web port is weaker than the marketing suggests, and this matters because #259 named it as the
leading candidate.

Its 30 expressions do work the way the issue hoped. `head` (48 variants, face plus hair as one merged
layer) and `expression` (30 variants, eyes plus brows plus mouth as one 227x253 layer) are separate
components with no per-variant offsets, so the expression overlay lands in the same place on every
head. I confirmed by rendering the same character across 12 expressions: identity holds, only the
face changes, and about 87% of the SVG output is byte-identical between two expressions of the same
character.

But there is no clothing component. The torso is a single fixed shape baked into the canvas as 8
static elements, recoloured from a 7-value palette of pastels. One body, no garments, no variety.
On the register axis the DiceBear port scores zero.

The full library on openpeeps.com does have poses, and the site does advertise sitting. I downloaded
all 14 sitting PNGs from the site's CDN and looked at them. They are people sitting **on the floor**,
cross-legged or knees-up, in t-shirts, tank tops, and sneakers. One is a wheelchair user. Not one is
seated at a table, and none is dressed like an attorney. The full library also ships only through
Gumroad (`https://gum.co/openpeeps`) as Sketch and Figma files, so there is no direct download and no
web runtime.

Expression is a merged layer, which means you cannot compose new states. You get the 30 that were
drawn, or you draw more.

### Notionists

The dark horse, and worth naming because it beats Open Peeps on register. CC0, 194 drawn parts, and
it has `clothes` (25) and `gesture` (10, hands and arms) as real components. Expression is
compositional across 13 eyebrows, 5 eyes, and 30 mouths.

Two things rule it out. Rendering all 25 garments, only variant19 and variant20 read as business, and
variant20 is the only one with a necktie. More decisively, the style is strictly black and white. Its
colour section defines exactly one ink colour and one paper colour, so there are no skin tones at all.
For a course built around a harassment lawsuit, where who the characters are is part of the material,
a cast that cannot vary in skin tone is a poor foundation.

### Humaaans

Humaaans is the frustrating one because it solves the axis nobody else touches. Full-body flat vector
figures in profile and three-quarter view, separate head, torso, and legs, and a dress register that
genuinely includes blazers, coats, and neckties. It is CC0 and by the same illustrator as Open Peeps.

The faces have no features. No eyes, no mouth, nothing. That is a deliberate style choice and it makes
Humaaans useless for a game whose entire budget goes on making reactions visible. It is also
Sketch-and-Studio only, distributed through Gumroad, with no web runtime.

Worth keeping in view as pose reference for whoever draws the commissioned set.

### Ruled out quickly

Kenney's 2D asset catalogue has no modular human character set with expressions. Live2D is
proprietary; the Cubism SDK is free during development but shipping requires a Publication Licence
Agreement, with exemptions for individuals and small enterprises and a 20,000,000 JPY annual sales
threshold for some categories. It is not open source and does not belong in this comparison except
to note it was checked.

## Licensing

### avataaars, and the wrinkle

DiceBear labels avataaars "Free for personal and commercial use" and points at
[avataaars.com](https://avataaars.com/) as the licence URL. That is not a licence. It is a line of
marketing copy on a page that reads, in full, "Designed by Pablo Stanley. Free for personal and
commercial use." No version, no attribution clause, no statement about derivatives.

It gets worse. avataaars.com's HTTPS certificate expired on 2021-12-21 and the certificate presented
is for an unrelated domain, `photoshopfordesignerswhodontusephotoshop.com`. The canonical licence URL
cannot be loaded over HTTPS at all. Relying on that page as your licence of record is not defensible.

The fix is to take the art from `fangpenlin/avataaars` instead, where it is properly licensed. That
repository's LICENSE is MIT and reads "Copyright (c) 2017 Pablo Stanley, Fang-Pen Lin", naming the
illustrator himself as a copyright holder. Its `package.json` declares `"license": "MIT"`. The artwork
is not a separate download; it is SVG path data embedded in the TypeScript components under
`src/avatar/`, including `src/avatar/clothes/BlazerShirt.tsx` and the twelve mouths in
`src/avatar/face/mouth/`. The MIT grant covers those files.

MIT permits commercial use and derivatives. It requires that "The above copyright notice and this
permission notice shall be included in all copies or substantial portions of the Software", so ship
the MIT text and the Pablo Stanley / Fang-Pen Lin copyright line in a third-party notices file.

Classroom and commercial use are both fine. Recommend citing the GitHub repo as the licence of record
and not avataaars.com.

### CC0 styles (Open Peeps, Notionists, Humaaans)

[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/): the rights holder "has dedicated the
work to the public domain by waiving all of his or her rights to the work worldwide under copyright
law", and you may "copy, modify, distribute and perform the work, even for commercial purposes, all
without asking permission." No attribution required, though crediting Pablo Stanley and Zoish costs
nothing and is good manners.

Two caveats the deed states plainly. Patent and trademark rights are untouched, and the dedication
"makes no warranties about the work, and disclaims liability for all uses of the work". Publicity and
privacy rights also survive CC0, which is worth remembering if a generated character ends up
resembling a real person.

### CC BY 4.0 styles (Big Ears, Personas, Adventurer, Micah, Croodles, Toon Head)

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) lets you "Share" and "Adapt" the material
"for any purpose, even commercially", but you "must give appropriate credit, provide a link to the
license, and indicate if changes were made." That last clause is the one people forget. If you
recolour or extend the parts, you have to say so. There is also a no-additional-restrictions clause:
you "may not apply legal terms or technological measures that legally restrict others from doing
anything the license permits."

Workable, but it puts a standing attribution obligation on a student-facing app. Since the
recommended path is MIT, this only matters if a CC BY style gets mixed in later.

DiceBear's own [licences page](https://www.dicebear.com/licenses/) counts 42 CC0 styles, 14 CC BY 4.0,
1 MIT, and 4 under artists' own terms, and says the summaries there are "meant as orientation, not as
legal advice." It gives users no guidance on discharging CC BY attribution, so that work is yours.

Nothing I found in any candidate carries a non-commercial or no-derivatives clause. That risk did not
materialise.

## The honest gap

What avataaars gives you: a recognisable adult face that can hold roughly eight distinct emotional
states without any new art, in three plausibly professional garments, with real skin-tone variation,
under MIT.

What it does not give you, and what no library gives you:

**Seated figures.** Every candidate is a bust. There is no arm, no hand, no lower body, no table.
The game's premise is people across a conference table from each other and that image does not exist
off the shelf.

**Anything but front-facing.** No three-quarter, no profile. Two characters facing each other requires
art drawn at an angle, and a face turned three-quarter needs its entire expression set redrawn,
because eyes and mouth do not survive a rotation.

**Adult proportions.** avataaars has a large head on small shoulders. It reads as friendly and a bit
juvenile. Fine for a profile picture, arguably wrong for a judge. Whether that matters is a taste call
for the course owner, not a technical one, but it should be a conscious choice.

**Gesture.** Notionists has 10 hand and arm parts and is the only library that does. Sliding a
settlement offer across a table, or a client's hands folded tight, is a big part of making a
negotiation beat visible, and it is all missing.

So the honest summary is that avataaars solves the expression axis outright and the register axis
about a third of the way. The pose axis is entirely unsolved and always will be, because no avatar
library is built to draw a scene.

## Part-count estimate

Both options assume one shared head geometry so expression parts are reusable across the whole cast,
which is how avataaars is already built. Assume six recurring characters (client, opposing counsel,
judge, mediator, and two witnesses) and eight emotional states.

**Option A, bust-only in business dress. About 50 parts.**

| Group | Count | Notes |
| --- | --- | --- |
| Eyebrows | 8 | Spans the negotiation emotional range |
| Eyes | 8 | |
| Mouths | 10 | |
| Hair | 10 | Enough to distinguish six characters plus spares |
| Facial hair | 4 | |
| Glasses | 4 | |
| Business garments | 8 | Suit and tie, blouse, blazer, cardigan, shirtsleeves, judge's robe |
| **Total** | **52** | 8 x 8 x 10 = 640 expression combinations |

This is a reskin. It keeps avataaars' front-facing bust and only fixes the dress register. Roughly
half the size of the avataaars library.

**Option B, seated at a conference table in three-quarter view. About 115 parts.**

| Group | Count | Notes |
| --- | --- | --- |
| Expression parts, two head orientations | 52 | 26 parts redrawn for the three-quarter head |
| Hair, two orientations | 20 | |
| Facial hair and glasses, two orientations | 16 | |
| Garments, two orientations | 16 | Torso only, below the table is hidden |
| Arms and hands on table | 6 | Resting, gesturing, folded, per orientation |
| Chair backs and table edge props | 4 | |
| **Total** | **114** | Mirror the three-quarter set for left/right |

Add roughly 6 more for the room background (conference room, law office, courtroom).

The useful way to feel that number: **114 parts is the whole avataaars library (103) or the whole
Open Peeps DiceBear port (104), commissioned from scratch.** Those are complete, published, widely
used illustration libraries. Option B is not an extension of an avatar system, it is a small
illustration library with an avatar system's structure. Option A, at 52 parts, is genuinely an
extension and is the one I would scope first.

I can count parts rigorously because I measured every comparable library. I cannot give you a
defensible day rate or dollar figure from a primary source, and I am not going to invent one. What I
can say is that expression parts are small and fast once the style is locked, while three-quarter
torsos and garments are the slow, expensive part, and Option B roughly doubles the drawing work per
garment for exactly that reason.

A middle path worth considering: build Option A first, ship it, and fake the table with a foreground
prop layer and a room background behind the existing front-facing busts. Two busts angled toward each
other with a table edge drawn across the bottom gets most of the read for none of the three-quarter
redraw. If it works, Option B never needs funding.

## Constraints on the technical stack

For whoever is surveying browser stacks.

**Layered SVG, not sprite sheets.** Every serious candidate is layered SVG with plain `<path>`
elements and named colour references. No filters, no gradients, no raster. Runtime part swapping is
just re-rendering a string, so there is no animation runtime or texture atlas to budget for.

**Rendered file sizes are small enough to ignore.** Measured from the live API for a single composed
avatar: avataaars 5,292 bytes raw and 2,286 gzipped, Open Peeps 8,362 raw and 3,989 gzipped,
Notionists 11,676 raw and 5,390 gzipped. Six characters on screen in avataaars is about 14 KB
gzipped. Chromebook performance is a non-issue at this scale. The risk would be animating many paths
at once, not loading them.

**Self-hosting is a solved problem.** `npm install @dicebear/core @dicebear/styles`, then load a style
from a JSON file and call `avatar.toString()`. `@dicebear/core` is MIT, "Copyright (c) 2026 Florian
Körner". No network calls at runtime and no dependency on api.dicebear.com. Native libraries also
exist for PHP, Python, Rust, Go, Dart, and C# if the Rails side ever needs to render server-side.
The JS package is pure ESM and needs Node 22 or higher.

**The commissioned art has a ready-made delivery format, and this is the important one.** A DiceBear
style is a single JSON file conforming to a
[published schema](https://cdn.hopjs.net/npm/@dicebear/schema@1.4.0/dist/definition.min.json), holding
licence metadata, colour palettes, and every part as SVG path data. DiceBear ships a
[Figma plugin](https://www.figma.com/community/plugin/1005765655729342787) that exports one directly
from a Figma file: the illustrator names components `<group>/<option-name>`, assigns colours from
named colour styles, and the plugin produces the definition. So the pipeline is Figma to JSON to
`@dicebear/core`, with no custom rendering code and no asset build step. That is worth a lot. It means
the commission can be specified as a Figma file against a naming convention, and the illustrator never
has to understand the game.

Adding custom parts to an avataaars-derived set is also a well-trodden path outside DiceBear.
`ibonn/python_avatars` (MIT) exposes `install_part("suit.svg", pa.ClothingType)` for exactly this.

**Per-part control over the HTTP API works, with a naming trap.** Options are
`<component>Variant` and `<component>Probability` in the 10.x API, so `expressionVariant=serious`,
not `expression=serious`. Passing the wrong name is silently ignored and you get seed-default output
that looks correct. I lost time to this; the option list for any style is at
`https://api.dicebear.com/10.x/<style>/options.json`. Set `Probability` to 0 or 100 to force optional
components off or on.

## Not verified

- The full Open Peeps and Humaaans source libraries are Gumroad downloads requiring a checkout, so I
  assessed them from the individual SVG and PNG assets published on their own sites and from the
  DiceBear port. My claim that the full Open Peeps library lacks business attire and table-seated
  poses rests on the 14 sitting renders its own site publishes, not on the Sketch file's full layer
  list.
- No illustrator cost or timeline figure. The part counts are mine and are grounded in measurements
  of comparable libraries. Any money number attached to them would be invented.
- The "roughly eight emotional states" figure is a design assumption, not a research finding. It
  comes from the states named in #259 (pleased, wary, insulted, resigned) plus the obvious neighbours.
- I did not audit all 61 DiceBear styles visually. I pulled every definition and counted components
  programmatically, then rendered only the candidates whose component vocabulary suggested business
  dress or strong expression coverage.
