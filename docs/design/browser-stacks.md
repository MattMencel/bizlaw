# Browser stacks for a two-team legal negotiation simulation

Research notes for [MattMencel/bizlaw#260](https://github.com/MattMencel/bizlaw/issues/260).
Verified 2026-08-28. This is a trade-off survey, not a recommendation. No winner is named
on purpose.

## What this is answering

A college business-law course is being rebuilt as a browser-first, desktop-first,
asynchronous two-team negotiation simulation with 2D animated avatars and LLM-backed NPC
dialogue, maintained by one developer. The stack decision is being locked before anything
else, so the question here is which families can carry the boring half (instructor
dashboards, grading, auth, persistence) as well as the demo half.

Locked constraints, not relitigated: browser only, nothing installed, school Chromebooks,
asynchronous turn-based play, server-side LLM calls, instructor tooling in the same
product, layered-SVG avatars central, solo developer, no deadline.

## Method and honesty rules

Every claim below is traced to the source that owns it: official docs, release pages,
first-party pricing, package registries, or the framework's own repository. Secondary
write-ups and blog listicles were not used as evidence. Where a source is dated or
caveated, the date and caveat are carried through. Where nothing primary could be found,
the gap is stated in [What could not be verified](#what-could-not-be-verified) rather than
filled in.

Arithmetic I performed myself (cost estimates) is labelled as such and shows its
assumptions. Do not read those as verified figures.

## Where the project already stands

Worth stating because "greenfield" does not mean the developer starts from zero
experience, and the incumbent stack is one of the families under evaluation.

| Thing | Value | Source |
|---|---|---|
| Framework | Rails 8.0.5.1 | `Gemfile.lock` |
| Front end | Hotwire (`turbo-rails`, `stimulus-rails`), `importmap-rails`, `propshaft`, `tailwindcss-rails` | `Gemfile` |
| Auth | `devise` 5.0, `devise-jwt` 0.13, `omniauth-google-oauth2` 1.1 | `Gemfile` |
| Hosting | Fly.io | `fly.toml` |
| Browser test tooling | Playwright 1.62.1 via `playwright-ruby-client` | `package.json` |
| Accessibility testing | axe-core specs, run with `bundle exec rspec --tag accessibility` | `CLAUDE.md` |

The axe-core suite matters more than it looks. It means WCAG conformance is already
treated as a shipping requirement, and that turns out to be the single sharpest divider
between the families below.

---

## The Chromebook baseline: what is actually verifiable

This is where assumption does the most damage, so it is worth being strict about what is
established fact versus inference.

**Established.** ChromeOS devices receive "10 years of updates" measured "from the platform
release date," not the purchase date ([Chromebook Auto Update policy, support.google.com,
verified 2026-08-28](https://support.google.com/chrome/a/answer/6220366)). A school
therefore has a supported, in-warranty reason to still be running a platform released in
2017 or 2018. Planning against current retail hardware is planning against the wrong
device.

**Established.** "Chromebook Plus" is a certification floor, not a typical spec: Intel Core
i3 12th gen or above / AMD Ryzen 3 7000 series or above, 8GB+ RAM, 128GB+ storage, Full HD
IPS display ([Google Chromebook Plus, verified
2026-08-28](https://www.google.com/chromebook/chromebookplus/)). This is the ceiling of
what a classroom might have, not the floor.

**Established.** WebGPU shipped in Chrome 113 (April 2023) and its initial release covered
"ChromeOS devices with Vulkan support, Windows devices with Direct3D 12 support, and macOS"
([Chrome for Developers, updated 2023-04-06, verified
2026-08-28](https://developer.chrome.com/blog/webgpu-release)). "ChromeOS devices with
Vulkan support" is a real qualifier. A stack that requires WebGPU is a stack that has
excluded part of the room; a stack that requires only WebGL 2.0 has not.

**Established.** Chrome enforces cross-origin isolation for `SharedArrayBuffer`: desktop
Chrome 92 requires both `Cross-Origin-Embedder-Policy: require-corp` and
`Cross-Origin-Opener-Policy: same-origin`. Under isolation "your page will not be able to
load cross-origin content unless the resource explicitly allows it via a
`Cross-Origin-Resource-Policy` header or CORS headers," and `COOP: same-origin` "will break
integrations that require cross-origin window interactions such as OAuth and payments"
([developer.chrome.com/blog/enabling-shared-array-buffer, verified
2026-08-28](https://developer.chrome.com/blog/enabling-shared-array-buffer)).

That last sentence has a direct, checkable consequence for this project and it needs
stating precisely, because it is easy to overstate. The app's current
`omniauth-google-oauth2` flow is a top-level redirect, and a top-level redirect is not a
cross-origin *window interaction*, so it survives `COOP: same-origin`. What does not
survive is a popup or iframe based sign-in, which is what Google Identity Services' button
uses. So cross-origin isolation is not an automatic blocker for this codebase, but it
permanently forecloses one plausible future auth choice, and it makes every third-party
embed (a publisher's video, an LTI tool, an embedded gradebook widget) a header
negotiation. Treat it as a tax on the whole origin, not a setting on one page.

**Not verifiable.** I could not find a primary Google source stating the modal hardware
spec of Chromebooks actually deployed in US secondary and higher education. The AUE policy
and the Chromebook Plus floor bracket the range, but the middle of the distribution is a
gap. Anyone using this document should treat "what is actually in the classroom" as an
open question to answer by measurement, not by inference from these two endpoints.

---

## Family A: conventional server app with a rich client, animation in DOM/SVG/CSS

Rails, Django, or Phoenix on the server; Hotwire, HTMX, LiveView, React, or Svelte on the
client; avatars as live SVG in the document.

### Chromebook performance

The relevant fact is that SVG animation is GPU-composited by default. "As of Chromium 89,
Chrome will join the likes of Firefox to enable hardware-acceleration by default on SVG
animations," and "What do you, the developer, need to do? Nothing" ([Chrome for
Developers, updated 2021-02-22, verified
2026-08-28](https://developer.chrome.com/blog/hardware-accelerated-animations)). Chromium
89 shipped in 2021, comfortably inside the AUE window of anything a school is still
running.

The performance discipline is well documented and narrow: "Where possible, restrict
animations to `opacity` and `transform` to keep animations on the compositing stage of the
rendering path," and "Before using any CSS property for animation (other than `transform`
and `opacity`), determine the property's impact on the rendering pipeline" ([web.dev
animations guide, verified 2026-08-28](https://web.dev/articles/animations-guide)). An
avatar built as layered parts each moved by `transform` sits on the fast path. An avatar
that animates geometry attributes, filters, or layout does not. That is a constraint on
the art, and it is the main thing the art pipeline needs to hear from this family.

This family also has the lowest cold-start cost of any option here, because there is no
engine to download before the first frame.

### Layered-SVG avatars

This is the family SVG is native to. Parts are DOM nodes, so part-swapping is
`replaceChild` or a framework re-render, styling is CSS, and hit-testing is free.

Four animation approaches are all viable and all currently supported:

- **CSS transitions/animations** on `transform` and `opacity`, on the compositor path.
- **SMIL** (`<animate>`), which is *not* deprecated. MDN marks it "Baseline Widely
  available... available across browsers since January 2020," with no deprecation notice
  and no suggestion to migrate away ([MDN `<animate>`, verified
  2026-08-28](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/animate)).
  This surprised me and is worth knowing, since SMIL has a reputation for being dead that
  the primary source does not support.
- **Web Animations API**, for imperative control from JS.
- **GSAP**, which is now "100% free for all users, thanks to Webflow's support," with the
  formerly paid Club plugins including MorphSVG and DrawSVG included ([gsap.com/pricing,
  verified 2026-08-28](https://gsap.com/pricing/)). For a solo developer on a school
  budget this removed a real line item; it was a paid dependency not long ago.

MDN's own accessibility guidance on `<animate>` is worth carrying into the design: provide
a mechanism to pause or disable animation and respect the reduced-motion media query.

### Accessibility

SVG in the document is in the accessibility tree. Avatars can carry `role` and
`aria-label`, dialogue can be live-region announced, and the existing axe-core suite keeps
covering the game screens rather than stopping at their edge. No other family in this
survey can say that.

### Hosting at 200 concurrent

Cheap, and the cheapness is structural rather than lucky. Asynchronous turn-based play
means request rate is a function of human decision speed, not frame rate. Two hundred
students each acting once every thirty seconds is roughly seven requests per second.

Fly.io's published rates: `shared-cpu-1x` with 256MB is $2.02/month in Amsterdam;
`performance-1x` with 2GB is $32.19/month; volumes are $0.15/GB/month; North America and
Europe egress is $0.02/GB ([fly.io/docs/about/pricing, verified
2026-08-28](https://fly.io/docs/about/pricing/)). Seven requests per second of
form-submission traffic does not need a `performance` machine.

Rails 8 specifically removes the second bill. It ships Solid Queue, Solid Cache, and Solid
Cable as defaults, and the release note frames it exactly this way: before, "Rails needed
either MySQL or PostgreSQL as well as Redis to take full advantage of all its features,
like jobs, caching, and WebSockets. Now all of it can be done with SQLite" ([Rails 8
announcement, 2024-11-07, verified
2026-08-28](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required)). Background LLM
calls are a Solid Queue job against the database that is already there.

### Solo-developer load

Lowest of the three families, and the reason is that the boring half is the framework's
home ground. Instructor dashboards, grading, roles, soft deletion, CSV export, and audit
trails are what a mature server framework has scaffolding, conventions, and a decade of
answered questions for. Nothing about the game half forces a second runtime, a second
language, a second build system, or a second deployment target.

Phoenix LiveView deserves a specific note because it is often proposed for exactly this
shape of app. Current version is 1.2.11; it renders statically on first request, then holds
state in a server process over a WebSocket and ships only diffs to the browser
([hexdocs, verified 2026-08-28](https://phoenix-live-view.hexdocs.pm/welcome.html)). For
asynchronous turn-based play that is a good fit in principle. Two cautions. First, the
welcome guide says nothing about latency behaviour, reconnection, or per-connection memory
cost, so the operational envelope is not documented where you would first look for it.
Second, the famous "2 million connections" number is from 2015, on a 40-core / 128GB
machine, and the authors themselves caveat it heavily: it tested "exclusively around the
number of simultaneous open sockets," they call it "not a typical use case," the ceiling
was "limited by ulimit" rather than by Phoenix, and they had made no effort "toward
reducing the memory usage of each socket handler" ([Phoenix blog, 2015-10-28, verified
2026-08-28](https://www.phoenixframework.org/blog/the-road-to-2-million-websocket-connections)).
It is evidence that 200 connections is not a concern. It is not evidence about anything
else. The real cost of LiveView here is language surface for a solo maintainer, not
capacity.

### Where it hurts

Complex character animation is hand-rolled. There is no scene graph, no timeline editor, no
sprite batching, no asset pipeline for animation. If the avatars grow toward dozens of
simultaneously animating characters or particle-heavy scenes, this family runs out of road
before the others do. For two talking heads across a negotiation table, it does not.

---

## Family B: a game-engine web build embedded in or beside a conventional app

### Godot 4 web export

Current stable is 4.7.2, released 18 August 2026
([godotengine.org/download, verified
2026-08-28](https://godotengine.org/download/windows/)). Everything below is from the 4.7
documentation unless noted.

**Threading and hosting are better than their reputation, and it matters.** The old story
was that Godot web needed cross-origin isolation. That is no longer the default. Threads
are opt-in: "Only when exporting with **Use Threads**... Godot 4 web exports use
SharedArrayBuffer. This requires a secure context, while also requiring the following CORS
headers to be set when serving the files: `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`" ([Godot 4.7 web export docs, verified
2026-08-28](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html)).
The 4.3 progress report explains why single-threaded export exists at all: the Foundation
"tasked me to find a way to backport the ability to build Godot without using threads in
order to export Godot games without the pesky COOP/COEP headers," because "most Web games
are being published on third-party publishing platforms where the game authors may not even
be able to set the required headers" ([Godot blog, 2024-05-15, verified
2026-08-28](https://godotengine.org/article/progress-report-web-export-in-4-3/)).

So the honest framing is a fork, not a blocker. Ship single-threaded and you keep a normal
origin, normal OAuth, normal embeds, and you accept lower performance and sample-based
audio without effects. Ship threaded and you get performance and low-latency stream audio,
and you take on the origin-wide isolation tax described in the Chromebook section above.

**No WebGPU, WebGL 2.0 only.** "Forward+/Mobile are not supported on the web platform" and
"Godot currently does not support WebGPU, which is a prerequisite for allowing
Forward+/Mobile to run on the web platform." Only Compatibility rendering (WebGL 2.0) is
available. For this project that is fine and arguably a positive, since it removes the
Vulkan-on-ChromeOS question entirely.

**Download size is the real Chromebook cost.** "Currently, the 4.3 release Web build .wasm
is around 40 MB uncompressed, and 5 MB compressed with Brotli" (Godot blog, 2024-05-15).
The 4.7 docs add that "the WebAssembly module compresses particularly well, down to around
a quarter of its original size with gzip compression." A web export ships `.html`, `.wasm`,
`.pck`, `.js`, and a splash `.png`. In dollar terms this is nothing; at $0.02/GB, 200
students pulling 10MB each is about four cents. In classroom terms it is a lecture-hall
full of devices pulling a multi-megabyte engine over shared school Wi-Fi in the same two
minutes, before anyone sees a first frame. That is a scheduling problem, not a billing
problem, and it is the cost that actually gets noticed.

**Two documented limitations bite this specific product harder than they bite most games.**
"The project will be paused by the browser when the tab is no longer the active tab in the
user's browser." For an asynchronous, multi-hour, tab-switching classroom activity, an
experience that halts when a student opens another tab is a design constraint, and any
state that lives only inside the engine stops advancing with it. Separately, "Users must
allow cookies (specifically IndexedDB) if persistence of the `user://` file system is
desired," which in a managed-device environment is a policy question, not a user question.
Both are survivable by keeping authoritative state on the server and treating the engine as
a pure view, but that is a decision to make deliberately at the start.

**Accessibility is the decisive problem.** Godot renders to a canvas. The 4.7 web export
documentation contains nothing about accessibility, screen readers, DOM integration, text
input, or IME. Godot 4.5 introduced screen-reader support for Control nodes through
AccessKit ([Godot 4.5 release page](https://godotengine.org/releases/4.5/)), but AccessKit
covers desktop only, with Android, iOS, and Web "planned, but there is no timeline for it
at the moment" ([godotengine/godot PR #76829, verified
2026-08-28](https://github.com/godotengine/godot/pull/76829)). The 4.7 release page does
not mention the web platform at all
([godotengine.org/releases/4.7, verified 2026-08-28](https://godotengine.org/releases/4.7/)).

For a required college course this is not a polish item. Anything that happens inside the
canvas is invisible to a screen reader and invisible to the axe-core suite this repo
already runs. The mitigation is to keep all graded, required, and information-bearing
interaction in the DOM and let the canvas carry only decorative motion, which is a coherent
architecture but sharply limits what the engine is buying.

**Layered SVG does not survive contact with Godot.** Godot has no live SVG scene graph.
SVG is an import format that is rasterized at import time. Choosing Godot means choosing a
raster or engine-native art pipeline, and it forecloses runtime part-swapping of vector
layers as a DOM operation.

**Solo-developer load is the highest here**, because Godot is a second everything: second
language (GDScript), second editor, second build and export step, second deployment
artifact, second debugging environment, and a hard boundary between game state and the
Rails or Django models that grading reads from. Every piece of data the instructor
dashboard needs has to cross that boundary explicitly.

### PixiJS

Current version 8.20.1 ([npm registry, verified
2026-08-28](https://registry.npmjs.org/pixi.js/latest)), described as "the fastest 2D
WebGPU/WebGL renderer" ([pixijs.com, verified 2026-08-28](https://pixijs.com/)). Because it
supports WebGL as well as WebGPU it does not inherit the Vulkan-on-ChromeOS constraint, and
because it is a rendering library rather than an engine it adds no second toolchain, no
second language, and no multi-megabyte engine download. It is by far the lightest member of
this family.

Its SVG handling is the part that couples to the art decision. Pixi lists `.svg` among
supported texture formats with a `loadSvg` loader ([PixiJS 8.x assets guide, verified
2026-08-28](https://pixijs.com/8.x/guides/components/assets)), but that path rasterizes:
per the project's own SVG guide, texture-based SVGs do not scale cleanly and need a
resolution multiplier or re-rasterization on scale, while loading through `GraphicsContext`
retains vector scalability ([PixiJS 8.x SVG guide, verified
2026-08-28](https://pixijs.com/8.x/guides/components/assets/svg)). So layered SVG is
possible in Pixi, but only down the `GraphicsContext` path, and the parts become Pixi scene
objects rather than DOM nodes. The accessibility consequence is the same as Godot's: canvas
content is outside the accessibility tree.

### Phaser

Current version 4.2.1 ([npm registry, verified
2026-08-28](https://registry.npmjs.org/phaser/latest)). Phaser 4 is a ground-up rewrite of
the WebGL renderer with a node-based architecture and full WebGL2 support ([Phaser news,
April 2026, verified
2026-08-28](https://phaser.io/news/2026/04/phaser-4-renderer-faster-cleaner-and-built-for-modern-games)).
It is a game framework rather than a renderer, so it brings scenes, input, and a game loop
that this product mostly does not need, and the same canvas accessibility boundary that
Godot and Pixi have. The v3-to-v4 migration is recent enough that a solo developer should
expect the long tail of tutorials and Stack Overflow answers to still be describing v3.

---

## Family C: full-stack JS/TS, one codebase for game view and admin view

SvelteKit 2.70.3 ([npm, verified 2026-08-28](https://registry.npmjs.org/@sveltejs/kit/latest))
or Next.js 16.3.3 ([npm, verified
2026-08-28](https://registry.npmjs.org/next/latest)) are the current representatives.

The appeal is real and specific: one language across the server, the game view, the
instructor dashboard, and the state machine that drives NPCs, which means one set of types
covering the authored simulation content end to end. For the hybrid NPC model described
below, that is not a small thing.

Chromebook performance and SVG behaviour are identical to Family A, because it is the same
rendering path. Everything in the compositor and accessibility discussion above carries
over unchanged. Hosting cost is comparable, though the tooling nudges toward per-request
platforms rather than the single long-lived machine that Rails 8 encourages.

The cost is the boring half. Nothing in this family gives a solo developer what Rails gives
for admin CRUD, roles, soft deletion, exports, and audit trails. That work is not hard, it
is just unending, and it is the work that actually consumes a solo maintainer's years.
Against that, the specific thing the incumbent stack already has: UUID primary keys, the
`SoftDeletable` concern, PostgreSQL enums, and JSONB metadata columns are conventions with
migrations and tests behind them already.

### The middle option worth naming

Inertia.js removes the false choice between "server framework with a thin client" and "SPA
with a hand-built API." It advertises itself as "The Modern Monolith" and says "Develop
React, Vue, and Svelte SPAs with the elegance of server-side routing... No API required,"
supporting Laravel, Rails, Django, and Phoenix ([inertiajs.com, verified
2026-08-28](https://inertiajs.com/)). The Rails adapter documents itself as actively
maintained and supports React, Vue, and Svelte ([inertia-rails.dev, verified
2026-08-28](https://inertia-rails.dev/)).

This is the option that lets the game screen be a real Svelte or React component with a
full component-level animation model while the instructor dashboard stays plain server-
rendered Rails, with no second API surface between them. If the DOM/SVG path is chosen but
Hotwire feels too thin for a stateful animated game view, this is the escape hatch that
does not cost a rewrite of the boring half.

---

## The hybrid NPC model and the instructor preview requirement

The brief flags instructor preview as easy to overlook and a real differentiator. It is,
and the reason turns out not to be about rendering frameworks at all.

### What the preview requirement actually demands

The design is an authored state machine plus an LLM for surface wording only. The preview
question is: before running this on students, can an instructor see what will happen?

That splits cleanly, and the two halves have opposite properties.

**The authored half is deterministic and previewable by construction.** A state machine
with authored transitions can be enumerated, walked, diagrammed, and diffed. Any of the
three families can do this; what differs is the tooling within reach. The TypeScript
ecosystem has the strongest off-the-shelf answer: XState 5.32.6 ([npm, verified
2026-08-28](https://registry.npmjs.org/xstate/latest)) with Stately Inspector
(`@statelyai/inspect`), "a tool that allows you to inspect your application's state
visually... It primarily works with frontend applications using XState but can also work
with backend code," producing state-machine and sequence diagrams automatically
([stately.ai/docs/inspector, verified 2026-08-28](https://stately.ai/docs/inspector)).
Ruby and Elixir have capable state machine libraries but nothing equivalent for visual
inspection, so in those stacks the preview UI is something the solo developer builds.

**The LLM half cannot be previewed by replaying it, and this is the finding that should
change the design.** On current Claude models, `temperature`, `top_p`, and `top_k` are not
merely discouraged, they are rejected: "Setting `temperature`, `top_p`, or `top_k` to any
non-default value on Claude Opus 4.7 or later models, including Claude Opus 5, returns a
400 error." And on the escape hatch people reach for: "If you were using `temperature = 0`
for determinism, note that it never guaranteed identical outputs on prior models"
([Migrating to Claude Opus 5, verified
2026-08-28](https://platform.claude.com/docs/en/models/opus-5/migration-guide)).

So "preview by re-running the model with a pinned seed" is not available and, per the
vendor's own documentation, never really was. A preview built that way would show the
instructor something other than what the students get, which is worse than no preview.

### What follows from that

The preview requirement is a **persistence and content-modelling** requirement, not a
rendering one. The only design that makes an instructor preview truthful is to
**materialize** the NPC lines: generate them ahead of time, store them against the state
machine node that triggers them, and have the runtime read the stored string rather than
call the model in the student's request path. The instructor then previews the exact bytes
the students will see, because they are the same row.

Three things follow, all of which happen to be good independently:

1. **Pre-generation is cheaper.** The Message Batches API reduces "costs by 50% and
   increasing throughput," with "most batches finishing in less than 1 hour"
   ([Batch processing docs, verified
   2026-08-28](https://platform.claude.com/docs/en/build-with-claude/batch-processing)).
   Generating a case's dialogue as one batch after authoring is both half price and
   naturally aligned with the preview step.
2. **The student-facing request path stops depending on a third-party API being up.** A
   class of thirty students mid-negotiation does not care about the vendor's status page if
   the lines are already rows in Postgres.
3. **Grading gets a stable artifact.** An instructor disputing or reviewing a student's
   negotiation is looking at stored text, not at something regenerated.

Live generation still has a place for genuinely open-ended student input, but treating it
as the exception rather than the rule is what makes the preview honest.

Note that this repo has already been bitten by exactly this class of bug from the other
direction: commit `18ebcf8` fixed personality assignment that "claimed deterministic
assignment but seeded `Random.new` with `case_instance.id.hash`," where "`String#hash` is
salted per process, so a case drew a different personality pair every time the app
restarted." The instinct to make simulation content reproducible is already present in the
codebase; the LLM layer is where that instinct has to change shape rather than be applied
harder.

### Which family makes this cheapest

Materialized dialogue is a database table, an authoring UI, a batch job, and a diff view.
That is server-framework work, and Family A is where it is cheapest to build. Family C is
competitive and buys the XState inspector as a genuine head start on the state-machine
half. Family B is the worst fit, because the state machine and the dialogue store would sit
on the server anyway while the engine is a view that has to be fed across a boundary, so
the engine adds nothing to the preview story and adds a boundary to it.

---

## Hosting cost at 200 concurrent students

All unit prices verified 2026-08-28; the totals are my arithmetic and are labelled as
estimates.

**Compute.** Asynchronous turn-based play at 200 concurrent students acting roughly once
every 30 seconds is on the order of 7 requests/second. That is well inside a single Fly
`shared-cpu` or small `performance` machine. At published rates, `shared-cpu-1x`/256MB is
$2.02/month and `performance-1x`/2GB is $32.19/month in Amsterdam, with volumes at
$0.15/GB/month ([Fly pricing](https://fly.io/docs/about/pricing/)). Rails 8's Solid Queue /
Cache / Cable defaults mean no separate Redis bill
([Rails 8 announcement](https://rubyonrails.org/2024/11/7/rails-8-no-paas-required)).
Call it tens of dollars per month across every family. Compute is not a differentiator.

**Egress.** North America and Europe egress is $0.02/GB. Even the heaviest option here, a
Godot build at roughly 5MB Brotli-compressed engine plus assets, costs pennies for 200 cold
loads. Bandwidth is not a differentiator either. First-load *wall time* on shared school
Wi-Fi is, and it is the one place where Family B is measurably worse than A and C.

**LLM inference, which dominates everything above.** Verified unit prices: Claude Haiku 4.5
is $1/MTok input and $5/MTok output; Claude Sonnet 5 is $2/$10; Claude Opus 5 is $5/$25.
Batch requests are 50% off and prompt cache reads cost 10% of base input price
([Models overview, verified
2026-08-28](https://platform.claude.com/docs/en/about-claude/models/overview.md)).

My estimate, with assumptions stated: 200 students, 30 NPC lines each, ~2,000 input tokens
and ~300 output tokens per line. On Haiku 4.5 that is 12M input tokens ($12) and 1.8M output
tokens ($9), so roughly **$21 per full class cohort** at list price. Pre-generating through
the Batch API halves it; prompt caching of the shared case context cuts the input side
further. This is arithmetic on verified unit prices, not a measured figure, and the token
assumptions are guesses that should be replaced with a real measurement early.

The point is the ratio. Inference is the dominant recurring cost and it is identical across
all three families, because the calls are server-side by constraint. **Hosting cost should
carry almost no weight in the stack decision.** If cost is going to drive a decision, it
should drive the decision to materialize dialogue rather than generate it live, which is
the same conclusion the preview requirement reaches independently.

---

## Where each choice forces the art pipeline

Flagging this explicitly for the parallel avatar-systems research, since the two decisions
constrain each other and the constraint runs in both directions.

| Stack family | What it does to layered SVG | Coupling strength |
|---|---|---|
| A (DOM/SVG) | Native. Parts are DOM nodes, swapping is a DOM operation, styling is CSS, animation via CSS / SMIL / WAAPI / GSAP. Parts stay in the accessibility tree. | Leaves the art pipeline maximally free |
| C (full-stack JS/TS) | Identical to A; same rendering path, plus component-level animation models | Same as A |
| B, PixiJS | SVG-as-texture rasterizes and does not scale cleanly; vector scalability requires the `GraphicsContext` path, and parts become Pixi objects rather than DOM nodes | Constrains it: SVG survives, DOM semantics do not |
| B, Phaser | Canvas/WebGL sprite pipeline; SVG is a source format, not a runtime one | Strongly constrains it |
| B, Godot | No live SVG scene graph. SVG is rasterized at import. Runtime vector part-swapping as a DOM operation is not available | Forecloses the layered-SVG approach outright |

Two things the avatar effort should treat as decision-relevant:

**The compositor rule is an art constraint, not just an engineering one.** In Families A and
C, avatar motion built from `transform` and `opacity` on layered parts runs on the GPU with
no developer effort. Motion built from animated geometry attributes, filters, or anything
that triggers layout does not, and that is where low-end Chromebooks will show it. This
should shape how rigs are authored, not just how they are played back.

**GSAP being free changes what is affordable.** MorphSVG and DrawSVG, which are the plugins
a layered-SVG character rig would most plausibly want, moved from paid to free
([gsap.com/pricing](https://gsap.com/pricing/)). If the avatar research is weighing
techniques against licence cost, that particular constraint is gone.

**If a raster or engine-native pipeline is chosen for other reasons, Family B stops being a
penalty** on the art axis specifically. The accessibility and download-size arguments
against it are independent and still stand.

---

## Solo-developer maintenance load, summarized

Ranked by total surface a single person carries. This is judgement built on the verified
facts above, not itself a verified claim.

| | Runtimes | Languages | Build/deploy artifacts | Boring half | Game half |
|---|---|---|---|---|---|
| A | 1 | 1 + JS | 1 | Framework does it | Hand-rolled animation |
| C | 1 | 1 (TS) | 1 | Build it yourself | Component-level, good tooling |
| B | 2 | 2 | 2 | Framework does it | Engine does it |

Family B's row is the honest picture: it is the only one that pays for its game-half
strength with a permanent doubling of everything else, plus an explicit boundary that every
piece of graded data must cross.

Two smaller notes. Godot 4.7.2 released 18 August 2026, ten days before this was written,
so anyone evaluating it should expect version churn during the build. Phaser 4's rewrite is
recent enough that community answers will lag. Rails 8 has been stable since November 2024.

---

## The shape of the trade-off, stated plainly

There is no version of this where a game engine is free. The engine buys animation
authoring and costs a second toolchain, a multi-megabyte first load on shared school Wi-Fi,
a tab that pauses when students switch away, an art pipeline that cannot be layered SVG,
and content that is invisible to screen readers and to the axe-core suite this repo already
runs. For two animated characters at a negotiation table, the DOM already does the GPU-
composited work for free.

The genuine live question is not A versus B. It is A versus C: whether the value of one
language and one type system across the authored simulation content outweighs the value of
a mature server framework's answer to the boring half, for one person, over years. That is
a judgement about the maintainer, not about the technology, which is why it is not resolved
here.

---

## What could not be verified

Stated rather than filled in.

- **The modal spec of school-deployed Chromebooks.** No primary Google source found. The
  10-year AUE policy and the Chromebook Plus floor bracket the range; the middle is
  unknown. Measure it.
- **Real frame-rate numbers for layered-SVG avatars on low-end ChromeOS hardware.** No
  first-party benchmark exists for this. The compositor guidance is documented; the
  resulting performance on a 2018-platform Chromebook is not. Prototype and measure.
- **Godot 4.7 web export size.** The 40MB / 5MB Brotli figure is from the Godot blog and is
  explicitly about the 4.3 release build. I found no 4.7-specific published figure. Treat
  it as an order of magnitude, not a current number.
- **Phoenix LiveView's operational envelope.** Per-connection memory, reconnection
  behaviour, and latency sensitivity are not documented in the welcome guide. The 2015
  connection benchmark is not a substitute and its authors say so.
- **Inertia Rails version and supported Rails range.** The site documents itself as actively
  maintained but publishes no version matrix on the landing page.
- **Godot web accessibility timeline.** AccessKit web support is "planned, but there is no
  timeline for it at the moment." That is the most recent primary statement found; there is
  no date to plan against.

---

## Sources

All verified 2026-08-28.

| Claim area | Source |
|---|---|
| Godot web export, threads, COOP/COEP, WebGPU, limitations | https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html |
| Godot current stable 4.7.2, 18 Aug 2026 | https://godotengine.org/download/windows/ |
| Godot 4.7 release page (no web platform coverage) | https://godotengine.org/releases/4.7/ |
| Godot web export size, single-threaded rationale | https://godotengine.org/article/progress-report-web-export-in-4-3/ (2024-05-15) |
| Godot accessibility / AccessKit desktop-only | https://github.com/godotengine/godot/pull/76829 ; https://godotengine.org/releases/4.5/ |
| PixiJS 8.20.1 | https://registry.npmjs.org/pixi.js/latest ; https://pixijs.com/ |
| PixiJS SVG loading and rasterization | https://pixijs.com/8.x/guides/components/assets ; https://pixijs.com/8.x/guides/components/assets/svg |
| Phaser 4.2.1 and v4 renderer rewrite | https://registry.npmjs.org/phaser/latest ; https://phaser.io/news/2026/04/phaser-4-renderer-faster-cleaner-and-built-for-modern-games |
| SharedArrayBuffer / cross-origin isolation / OAuth breakage | https://developer.chrome.com/blog/enabling-shared-array-buffer |
| WebGPU Chrome 113, ChromeOS requires Vulkan | https://developer.chrome.com/blog/webgpu-release (2023-04-06) |
| SVG animations hardware-accelerated in Chromium 89+ | https://developer.chrome.com/blog/hardware-accelerated-animations (2021-02-22) |
| Compositor-safe properties (transform, opacity) | https://web.dev/articles/animations-guide |
| SVG SMIL `<animate>` Baseline widely available, not deprecated | https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/animate |
| GSAP free including MorphSVG / DrawSVG | https://gsap.com/pricing/ |
| ChromeOS 10-year AUE from platform release date | https://support.google.com/chrome/a/answer/6220366 |
| Chromebook Plus minimum specs | https://www.google.com/chromebook/chromebookplus/ |
| Turbo morphing / `data-turbo-permanent` | https://turbo.hotwired.dev/handbook/page_refreshes |
| Rails 8 Solid Queue/Cache/Cable, no Redis | https://rubyonrails.org/2024/11/7/rails-8-no-paas-required (2024-11-07) |
| Phoenix LiveView 1.2.11 architecture | https://phoenix-live-view.hexdocs.pm/welcome.html |
| Phoenix 2M WebSocket benchmark (heavily caveated, 2015) | https://www.phoenixframework.org/blog/the-road-to-2-million-websocket-connections |
| Inertia.js "no API required", adapters | https://inertiajs.com/ ; https://inertia-rails.dev/ |
| SvelteKit 2.70.3 / Next.js 16.3.3 | https://registry.npmjs.org/@sveltejs/kit/latest ; https://registry.npmjs.org/next/latest |
| XState 5.32.6 and Stately Inspector | https://registry.npmjs.org/xstate/latest ; https://stately.ai/docs/inspector |
| Fly.io machine, volume, and egress pricing | https://fly.io/docs/about/pricing/ |
| temperature/top_p/top_k rejected; temperature=0 never guaranteed determinism | https://platform.claude.com/docs/en/models/opus-5/migration-guide |
| Batch API 50% discount, most batches under 1 hour | https://platform.claude.com/docs/en/build-with-claude/batch-processing |
| Model pricing and context windows | https://platform.claude.com/docs/en/about-claude/models/overview.md |
| Rive plans and runtime licensing (context for art pipeline) | https://rive.app/pricing |
