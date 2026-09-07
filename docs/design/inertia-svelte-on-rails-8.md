# How Inertia and Svelte install onto Rails 8 today

Research notes for [MattMencel/bizlaw#313](https://github.com/MattMencel/bizlaw/issues/313).
The question: [ADR 0001](../adr/0001-stack-and-language.md) locked Inertia + Svelte for the
student game view but named no bundler — so what does the install actually look like against
this repo as it stands, and what does it drag in?

Verified 2026-09-06 against `inertia_rails` 3.22.0, `vite_rails` 3.11.1 / `vite_ruby` 3.10.5,
`@inertiajs/svelte` 3.7.0, Svelte 5.57.0, Vite 8.2.2.

## Method

Everything below traces to a primary source I fetched: generator source at a released tag,
package registry metadata, the projects' own docs and changelogs. No secondary write-ups.
Where upstream is ambiguous or recently changed, the change is named with its date rather
than smoothed over. Claims about *this repo* come from reading the worktree and are labelled
as such.

## Where this repo actually stands

Worth stating precisely, because the ticket's framing assumed one thing and the tree says
another.

| Thing | Value | Source |
|---|---|---|
| Rails | `~> 8.0.5`, `>= 8.0.5.1` | `Gemfile` |
| Asset pipeline gem | **none** | `bundle list` matches no `propshaft`, `sprockets`, `importmap-rails` or `tailwindcss-rails` |
| Layout | still calls `stylesheet_link_tag "application"` | `app/views/layouts/application.html.erb` |
| Stylesheet | `app/assets/stylesheets/application.css` exists | worktree |
| `bin/dev` | a two-line `exec ./bin/rails server` | `bin/dev` |
| `Procfile.dev`, `package.json`, `.node-version`, `.nvmrc` | absent | worktree |
| CSP initializer | present, entirely commented out | `config/initializers/content_security_policy.rb` |
| `.gitignore` | already ignores `node_modules/` and `/app/assets/builds/*` | `.gitignore` |
| CI | four Ruby-only jobs; no Node, no `assets:precompile` | `.github/workflows/ci.yml` |

So **Propshaft is not installed**. The [#283](https://github.com/MattMencel/bizlaw/issues/283)
strip took it out and left the `stylesheet_link_tag` call and the `app/assets` skeleton
behind. That reframes area 5 below: the question is not "will the JS bundler break
Propshaft", it is "does the ERB instructor console need an asset pipeline at all, and if so
who serves it". Those are separable, and the answer is more comfortable than the ticket
feared.

---

## 1. The bundler

**Upstream has exactly one answer, and it is Vite Ruby.** This is not a preference expressed
in prose; it is enforced in the installer's control flow.
[`install_generator.rb`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/install_generator.rb)
at v3.22.0:

```ruby
def install_vite
  unless install_vite?
    say_error 'This generator only supports Ruby on Rails with Vite.', :red
    exit(false)
  end
  # ... bundle add vite_rails; bundle exec vite install
```

Decline the Vite prompt and the generator exits non-zero. There is no `jsbundling-rails`
branch, no esbuild branch, no importmap branch. The
[frameworks.yml](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/frameworks.yml)
manifest that drives package installation is keyed only on `react` / `vue` / `svelte`, and
every entry installs `vite@latest` and `@inertiajs/vite`.

The coupling reaches past the installer into runtime config. The generated initializer is:

```ruby
InertiaRails.configure do |config|
  config.version = ViteRuby.digest
  # ...
end
```

([`templates/initializer.rb`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/templates/initializer.rb).)
Inertia's asset-version mechanism — the thing that forces a full page reload when the client
bundle goes stale — is wired straight to `ViteRuby.digest` by default. On another bundler you
supply that digest yourself.

The docs match the code. [Server-side setup](https://inertia-rails.dev/guide/server-side-setup)
says the generator "automatically detects if the Vite Rails gem is installed"; the manual
section covers only the root ERB template, not an alternative bundler.
[Client-side setup](https://inertia-rails.dev/guide/client-side-setup) notes that
`@inertiajs/vite` "supports Vite 7 and Vite 8" and offers a manual path for people who do not
want *the plugin* — not for people who do not want Vite.

**What the alternative would actually cost.** `jsbundling-rails` offers bun, esbuild,
rollup and webpack, bundling into `app/assets/builds` "then deliver it via the asset pipeline
in Rails" ([README](https://github.com/rails/jsbundling-rails)). Three separate problems
follow for a Svelte + Inertia app:

1. None of the four installers knows about Svelte. esbuild does not compile `.svelte` files;
   you would add `esbuild-svelte` and hand-write the build script.
2. Delivering through the asset pipeline means adding Propshaft *because of* the bundler —
   the opposite of the coexistence worry.
3. You lose HMR (jsbundling's model is `yarn build --watch` plus a page refresh) and you
   hand-write the Inertia page-resolution glob that `@inertiajs/vite` generates.

I found no first-party Inertia documentation for a non-Vite Rails setup. A search restricted
to `inertia-rails.dev`, `inertiajs.com` and `github.com` surfaced only third-party starter
kits listed on the [Awesome page](https://inertia-rails.dev/awesome). Treat non-Vite as
unsupported-but-possible, not as a documented option.

**Conclusion for area 1: the bundler question is already decided upstream.** Choosing
anything but Vite Ruby means leaving the paved path for a project whose whole premise is one
reviewer and agent-written code.

## 2. Does the generator do the work?

Mostly yes. Running `rails generate inertia:install --framework=svelte --vite --no-typescript
--no-tailwind` (flags exist for every prompt; `--interactive=false` requires all of them) does
the following, read off the generator source and vite_ruby's
[`cli/install.rb`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_ruby/lib/vite_ruby/cli/install.rb)
and [`vite_rails/cli.rb`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_rails/lib/vite_rails/cli.rb):

**Gems added** — `vite_rails` (via a literal `bundle add vite_rails`).

**npm packages added** — `@inertiajs/svelte@latest`, `@inertiajs/vite`, `svelte@5`,
`@sveltejs/vite-plugin-svelte`, `vite@latest`; plus `vite` and `vite-plugin-ruby` as
devDependencies from vite_ruby's own install (`DEFAULT_VITE_VERSION = "^8.0.0"`,
`DEFAULT_PLUGIN_VERSION = "^5.2.0"`, from
[`version.rb`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_ruby/lib/vite_ruby/version.rb)).

**Files created** — `package.json` (`{"private": true, "type": "module"}`), `vite.config.ts`,
`config/vite.json`, `bin/vite`, `svelte.config.js`, `app/frontend/entrypoints/application.js`,
`app/frontend/entrypoints/inertia.js`, `config/initializers/inertia_rails.rb`,
`app/controllers/inertia_controller.rb`, `Procfile.dev`, `bin/dev` (chmod 0755), and — unless
`--no-example-page` — an example controller, route, `root`, and
`app/frontend/pages/inertia_example/index.svelte` plus four SVGs.

**Files edited** — `Gemfile`, `.gitignore` (adds `/public/vite*`, `node_modules`, `*.local`),
`config/routes.rb` (a `root`, an example route, **and a redirect constraint rewriting
`127.0.0.1` to `localhost`** so the browser origin matches the Vite dev server),
`app/views/layouts/application.html.erb` (`vite_client_tag`, `vite_javascript_tag "inertia"`,
`inertia_ssr_head`), `config/initializers/content_security_policy.rb` (commented-out CSP
guidance), and `bin/setup` (inserts `system! "npm install"`).

**What a human still does by hand.** Six things, and none of them is optional here:

- **Pin Node.** Nothing in either installer writes `.node-version`, `.nvmrc`, or an `engines`
  block — I read both installers' file-writing paths end to end. Vite 8.2.2 declares
  `engines.node: "^20.19.0 || >=22.12.0"` and `@sveltejs/vite-plugin-svelte` 7.3.0 declares
  `"^20.19 || ^22.12 || >=24"` (npm registry metadata, 2026-09-06). Pick one and commit it.
- **Decide about `app/assets`.** See area 5.
- **Reconcile `bin/dev`.** The generator overwrites this repo's `bin/dev`; the new one shells
  to overmind/hivemind/foreman against `Procfile.dev`.
- **Clean the routes.** The example `root` and `inertia-example` route land in
  `config/routes.rb` unless suppressed, and the `127.0.0.1` redirect constraint is a global
  catch-all worth reading before it ships.
- **Clean the CSP initializer.** This repo's CSP block is entirely commented out, so
  `inject_line_after csp_file, "policy.script_src"` will splice guidance into a comment
  block. Cosmetic, but it will look like a mistake in review.
- **Teach CI to build assets.** See area 6.

One sharp edge: the generator's package-manager detection returns `nil` when there is no
`package.json`
([`js_package_manager.rb`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/js_package_manager.rb)),
which is exactly this repo's state. That is the branch that triggers the Vite install; vite_ruby
then falls back to `npm` when no lockfile exists
([`config.rb#detect_package_manager`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_ruby/lib/vite_ruby/config.rb)).
So you get `package-lock.json` unless you pass `--package-manager=`.

## 3. Svelte version and idiom

**Svelte 5, runes, no ambiguity, and the ambiguity was removed recently enough to matter.**

- `@inertiajs/svelte` 3.7.0 (published 2026-08-18) declares `peerDependencies: {"svelte":
  "^5.0.0"}` (npm registry). The 2.x line, still published as the `legacy` dist-tag at 2.3.27,
  allowed `"^4.0.0 || ^5.0.0"`. The narrowing happened at 3.0.0 (2026-03-25).
- The [upgrade guide](https://inertiajs.com/upgrade-guide) states "The Svelte adapter now
  requires Svelte 5. Svelte 4 and below are no longer supported" and "All Svelte code should
  be updated to use Svelte 5's runes syntax (`$props()`, `$state()`, `$effect()`, etc)".
- `inertia_rails` 3.13.0 (2025-11-19) records "Remove Svelte 4 option in installation
  generators" ([CHANGELOG](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/CHANGELOG.md)).
  The vestigial `framework.start_with? 'svelte'` check in the generator is the scar.
- The generator's own templates are runes throughout. Its example page opens `let {
  rails_version, rack_version, ruby_version, inertia_rails_version } = $props()`
  ([`InertiaExample.svelte`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/templates/svelte/InertiaExample.svelte)),
  and the scaffold templates use `$props()` plus `{#snippet children({ errors, processing })}`
  rather than slots
  ([`form.svelte.tt`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia_templates/scaffold/templates/svelte/form.svelte.tt)).
- The store idiom is gone from the adapter's public API too. `packages/svelte/src/index.ts`
  exports `default as page` and the docs' [shared data](https://inertiajs.com/shared-data)
  Svelte example reads `{page.props.auth.user.name}` — no `$` auto-subscription. The generated
  scaffold matches, with `{#if page.flash.notice}`.

**The practical consequence: training data is the hazard here.** Any Svelte-Inertia snippet
written before roughly March 2026 uses `$page`, `export let`, and slots, and none of it will
work. Agents writing this code need the runes rule stated explicitly, not inferred.

The adapter's own toolchain pins `typescript: ^6` and `vite: ^8` in devDependencies
([`packages/svelte/package.json`](https://github.com/inertiajs/inertia/blob/master/packages/svelte/package.json)),
and `frameworks.yml` pins `typescript@^6` for the TS path with the comment that svelte-check
uses an API "gone from TypeScript 7's package entry". If you take the TypeScript branch, that
pin is load-bearing.

## 4. SSR

**Opt-in, off by default, and declining it costs nothing.**

The installer has no `--ssr` flag and generates no SSR entrypoint — I read every
file-writing method. The gem's defaults hash carries `ssr_enabled: false`
([`configuration.rb`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/inertia_rails/configuration.rb)),
and the generated initializer does not mention SSR at all. Enabling it is four deliberate
steps per the [SSR guide](https://inertia-rails.dev/guide/server-side-rendering): an
`inertia({ ssr: { entry: ... } })` block in `vite.config.ts`, a `vite build --ssr` in the
build script, `config.ssr_enabled = ViteRuby.config.ssr_build_enabled`, and `plugin
:inertia_ssr` in `config/puma.rb`, which "automatically starts and stops the SSR Node.js
process alongside Puma".

The only residue in a non-SSR install is one line, `<%= inertia_ssr_head %>`, inserted into
the layout. With `ssr_enabled: false` it renders nothing. Leave it or delete it; nothing
depends on the choice.

**This is the ADR 0001 answer.** "Node survives as a build-time dependency only" is satisfied
by the default install, not by opting out of something. The Puma plugin is the only thing that
would put a Node process in the request path, and you have to add it on purpose.

## 5. Coexistence with Propshaft and CSS

**Vite Ruby does not touch the asset pipeline. They pass each other in the dark.**

Vite's output goes to `public/vite`, is resolved through Vite's own manifest by
`vite_javascript_tag` / `vite_stylesheet_tag`
([`tag_helpers.rb`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_rails/lib/vite_rails/tag_helpers.rb)),
and is served as a static file — never through Propshaft's load path. In development a
`ViteRuby::DevServerProxy` middleware is inserted at position 0
([`engine.rb`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_rails/lib/vite_rails/engine.rb)).
Propshaft would continue to serve `app/assets/stylesheets/application.css` at `/assets/...`
with its own digest, untouched. The two overlap in exactly one place: the rake task. vite_ruby
*enhances* `assets:precompile` rather than replacing it —

```ruby
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do |task|
    Rake::Task["#{prefix}vite:install_dependencies"].invoke
    Rake::Task["#{prefix}vite:build_all"].invoke
```

— and defines the task itself only when nothing else has
([`vite.rake`](https://github.com/ElMassimo/vite_ruby/blob/main/vite_ruby/lib/tasks/vite.rake)).
Propshaft's precompile runs first, Vite's build appends. That is a genuine coexistence
guarantee, not an accident.

The one Rails-side reach-in is `app.config.javascript_path = app/frontend`, set in vite_rails'
engine initializer. That affects where Rails generators put JS. It does not move `app/assets`.

**CSS.** Three paths, and this repo has not chosen one:

- **The generator's Tailwind option** installs `tailwindcss`, `@tailwindcss/vite`,
  `@tailwindcss/forms`, `@tailwindcss/typography`, adds the plugin to `vite.config.ts`, writes
  `app/frontend/entrypoints/application.css`, and adds `vite_stylesheet_tag "application"` to
  the layout. This is Tailwind **v4 through Vite**, not `tailwindcss-rails`. It would style the
  ERB console too — but only via a Vite tag, meaning the ERB layout starts depending on the
  Vite manifest, and therefore on a Vite build, for its stylesheet.
- **Propshaft plus plain CSS** for the ERB console, Vite for the game view. Two independent
  pipelines, no Vite dependency in the instructor console's request path. Costs a `propshaft`
  gem and duplicate design tokens.
- **Neither.** Which is the current state: `stylesheet_link_tag "application"` with no gem
  behind it, emitting a link to a 404. That is a pre-existing loose end from #283 rather than
  something this work introduces, but it has to be settled when the layout is next touched.

## 6. What lands in the repo

- **`package.json`** at the root, `"type": "module"` — which is why the Vite config stays
  `.ts` rather than being renamed `.mts` (vite_ruby renames it when `type` is not `module`).
- **Lockfile: `package-lock.json`**, on the npm fallback described in area 2, unless you pass
  `--package-manager=pnpm|yarn|bun`.
- **Node pin: none, and you need one.** Neither installer writes `.node-version`, `.nvmrc` or
  `engines`. Vite 8 needs `^20.19.0 || >=22.12.0`. Add the pin in the same commit as the
  install or CI and the laptop will drift apart.
- **`Procfile.dev`** — two lines, `web: bin/rails s` and `vite: bin/vite dev`, appended by the
  two installers in that order.
- **`bin/dev`** — Inertia's own template
  ([`templates/dev`](https://github.com/inertiajs/inertia-rails/blob/v3.22.0/lib/generators/inertia/install/templates/dev)),
  a POSIX shell script preferring `overmind`, then `hivemind`, then `gem install foreman`.
  It **overwrites** this repo's two-line Ruby `bin/dev`.
- **CI has to grow a Node step.** No current job installs Node or precompiles assets. Once
  `assets:precompile` is enhanced, a deploy or asset build runs `npm ci` (the exact command,
  from `vite:install_dependencies`) followed by `vite build`. The `Dockerfile` also has no Node
  stage and no `assets:precompile` call — both need adding before a container ships a game
  view.
- **Test environment.** `config/vite.json` sets `"autoBuild": true` for both development and
  test, with `publicOutputDir: "vite-test"` and port 3037. So Capybara specs will trigger a
  Vite build on demand rather than needing an explicit build step — convenient locally, and a
  cold-cache cost in CI worth measuring before assuming either way. Nothing in the current
  RSpec or Cucumber suites touches assets, so `bundle exec rspec` and `bundle exec cucumber`
  are unaffected until there is a room to render.

**Does this honour ADR 0001's "Node survives as a build-time dependency only"?** Yes, on the
default install. Node appears in `assets:precompile` and in `bin/vite dev`. The request path in
production serves static files out of `public/vite` through Rails and Thruster. The single
thing that would violate the ADR is the SSR Puma plugin, which is opt-in and which nothing
here needs.

---

## Recommendation

**Take the paved path: `rails generate inertia:install --framework=svelte --vite
--no-typescript --no-tailwind --no-example-page`, then add the four things the generator does
not.**

The reasoning is not that Vite Ruby is the best bundler in the abstract. It is that upstream
has collapsed the option space to one, and this project's binding constraint is review
capacity. Every step off the paved path — esbuild plus `esbuild-svelte`, a hand-written page
resolver, a hand-supplied asset version digest, Propshaft delivery of a Svelte bundle — is
code that only this repo has, that no upstream test covers, and that a reviewer has to hold in
their head. Vite Ruby is also *less* entangled with Rails than the alternative: it does not
put the Svelte bundle through Propshaft, so the ERB instructor console and the game view stay
genuinely independent.

Concretely:

1. Run the generator with the flags above. Reverting a bad run is `git checkout` plus deleting
   `node_modules`; the risk is low enough to just try it.
2. **Pin Node** — `.node-version` at 22 or 24, and mirror it in CI with `actions/setup-node`
   and in the Dockerfile.
3. **Do not enable SSR.** No entrypoint, no `ssr_enabled`, no `plugin :inertia_ssr`.
4. **Decide CSS deliberately, and separately.** My inclination is Propshaft + plain CSS for
   the ERB console and Vite for the game view, so the instructor console never depends on a
   Vite build to render. But this is the one genuinely open call in the survey, and it is
   cheap to defer until the console has more than a layout.
5. **Restore `bin/dev` intent and clean the routes** in the same commit, so the diff a
   reviewer reads is the install and nothing else.
6. **Write the runes rule into `CLAUDE.md`.** Svelte 5 runes, `page` not `$page`, `$props()`
   not `export let`. Pre-2026 Svelte-Inertia idiom is confidently wrong and agents will
   produce it by default.

**What would change this answer.**

- **If the game view turns out not to need HMR or component-level animation** — if the
  boardroom is simpler than ADR 0001 assumed — then Inertia itself is the thing to revisit,
  not the bundler. Rails 8 + Hotwire needs no Node at all, and the ADR rejected it on the game
  view's richness rather than on anything structural.
- **If Propshaft turns out to be required for the ERB console anyway** (Active Storage
  variants, Action Text, or a real stylesheet), the jsbundling comparison narrows, because its
  main tax — dragging in an asset pipeline you did not want — stops being a tax. It would
  still cost HMR and a hand-written Svelte build.
- **If `inertia_rails` regains a non-Vite installer path.** It had a Svelte 4 option as
  recently as November 2025 and dropped it; this installer changes shape often enough that the
  reading has a shelf life. Re-check the generator source, not the prose docs, before the next
  major install decision.

## What could not be verified

- Whether the `vite:install_dependencies` / `vite build` step adds meaningfully to CI wall
  time for a bundle this small. That is a measurement to take after the first install, not a
  number to guess.
- Whether `autoBuild: true` in the test environment behaves well under a parallel Cucumber
  run. Nothing in the current suites exercises it.
