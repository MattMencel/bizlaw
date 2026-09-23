# CLAUDE.md

Engine for a two-team, asynchronous legal negotiation simulation used in college business law courses. Two student teams take opposing sides of one authored case and negotiate toward a settlement their client will accept, across a calendar of Days; an instructor runs sections, drives the clock and grades.

The engine is Apache-2.0 and lives here. Authored Cases are proprietary content and live in a separate private repository.

## State of the repository

Early. A Rails 8 skeleton on SQLite holds the authored Case — Version, calendar, Clients, Terms, documents, the Action menu — and a run: Organization, Section, Simulation, Sides and Days. A Day has two Budget halves: preparation, spent on authored Actions, and exchange, spent on the Offer commit and the Exhibits riding it. There is no authentication, roster or Pairing; `users` holds only what Attribution needs. Nothing draws from the Simulation seed for the Event Deck yet. The one screen is the demo at `/demo/:run(/:seat)`, and its rules are in `.claude/rules/demo-surface.md`.

- **The Offer commit is the one spend with no authored Action.** `docket_entries.case_action_id` is nullable and CHECKed to the exchange half, because a `case_actions` row for it would put the commit on the Action Board past the Second.

- **An Exhibit rides the staged Offer, never the commit.** The teammate who Seconds is confirming the whole play, so the commit quotes the Offer plus `case_versions.exhibit_price` for each Exhibit as one price and refuses entirely when the half cannot cover it. `Command#apply` re-reads the draft and requotes inside the charge's transaction, since staging is ungated.

- **A served document gives knowledge, never ammunition.** `case_file_documents.served_at` strips the Exhibit property on read, and found outranks served. Both player-caused shift kinds key `source_ref` to the receiving Side's own Case File row (ADR 0003); the seams ask the ledger before writing rather than letting the partial unique index raise.

- **`simulations.seed` never moves** — `attr_readonly` over a `BEFORE UPDATE` trigger — because a Consult's memo row is permanent. The seed and the speak count choose a Consult's variant, and the count counts the node, which is the band.

- **A write's refusals and its affordance are one list.** `WorkingDraft#may_draft?` is exactly `Offers::Stage`'s refusals, and `Offers::Accept.refusal_for` serves both the acceptance block and the write.

- **A race into a closed or executed Day is refused by the database.** The `..._an_unexecuted_day` triggers and the `RACED_CLOSE`/`RACED_COMMIT` rescue in `Offers::Stage` turn the fault back into the seam's own refusal. A re-read inside the transaction only holds while SQLite serialises writes, so the guard stays in the schema (ADR 0002).

- **After a settlement no Day is sitting.** `sitting_day` would return a Day `Simulations::Create` laid down and `Days::Open` never reached, so the executed surfaces ask for no Day.

A Case is loaded through one seam, `Cases::Import`, from a YAML file — `db/cases/reference.yml` is the engine's own minimal reference Case, not authored teaching material. `rake case:import[path]` runs it. `Simulations::Create` is the only path that lays out a Simulation, `Days::Land` is the only path that materialises what an Action yielded, `Exhibits::Play` the only path a played Exhibit lands through — the `played_exhibits` row an Exhibit is spent by, the shift against the *opposing* Client where the Offer touches a Term the Exhibit bears on, and the served copy in the other Team's Case File, all inside the commit's transaction — `Days::Close` is the only path that closes a Day — `Days::Commit`, `Days::FireDeadlines` and the Instructor's force-close all call it, and a second path that "also closes the Day" is the bug that shape exists to make impossible — `Days::Command` is the only writer to a Day's Budget and Docket ledgers — the Day commit and the Instructor's powers sit beside it, because `Command`'s two verbs exist to confirm a spend and none of those has a cost to confirm. Every act enters through it with two verbs, `quote` — which computes the cost, the half, what is left today and the landing Day, writes nothing, and returns a refusal rather than raising — and `apply`, which performs it. The confirmation a student reads is rendered from `quote`, so add an act to that seam rather than beside it. `Offers::Stage` is the only path that puts a position on a Team's table, and `Offers::Accept` the only path by which the other Side takes it; both sit beside `Command` for the same reason `Days::Commit` does: they cost nothing, so there is nothing to confirm. The waiver-or-Second gate the commit and the Acceptance share is `Second`, one predicate rather than two. The Docket a teammate reads is `Docket`, a fold over the spend ledger, the staged Offers and the Instructor's waivers, because only the first of those is a spend. `Side#reaction_band(as_of:)` is the only path a Reaction Band is answered by — folded from the shift ledger as of the spend's own `created_at` and stored nowhere, which is why `Cases::Import` refuses a Case authoring a document behind `consult_client`: a Consult that yielded paper would write its shift in the spend's own transaction and tie with it (ADR 0006). `ConsultMemo` is the read over that row, the Consult's counterpart to `ExecutedInstrument`. `Portraits::Compose` is the only path a Client's face is drawn through, and it takes the **render size** as an argument rather than emitting one file per state for CSS to resize — a halftone screen is fixed in ink on the page, so the pitch is divided back out by the render scale and an unserved size is refused. A read hands on the seed and the expression and never a rendered portrait; see ADR 0008.

`CONTEXT.md` is the domain glossary and the source of the vocabulary the code should use. Read it before naming anything.

## Conventions that differ from Rails defaults

These come from `docs/adr/0002-runtime-schema.md`, and getting them wrong produces migrations and queries that look correct but aren't:

- **Everything that moves is an append-only ledger, derived on read.** Action Budget remaining, a Client's reservation point, bound consumed, Reaction Band, Case File membership, Exhibit spent-state and Simulation status are folds over rows, not columns. There is no status column anywhere. It is not event sourcing — ordinary Rails tables, no projections, no replay.
- **`day_budgets`'s spent counters are the one materialized exception** — a preparation pair and an exchange pair in one row, each carrying `CHECK (spent <= budget)` and maintained by an `AFTER INSERT` trigger on `docket_entries` that re-folds the sum rather than incrementing it. Adding a second materialized aggregate needs an ADR, not a migration.
- **The rule for a ceiling is what it does when reached.** A ceiling that refuses gets a database CHECK; a ceiling that saturates gets a value computed by the model. The Client's bound saturates, so it is never a CHECK — one placed there would crash on a legal play.
- **`schema_format` is `:sql` and the repo tracks `db/structure.sql`.** Triggers do not survive a `schema.rb` dump. `spec/schema_format_spec.rb` proves the format still round-trips one.
- **Deletion is hard deletion, on Retention's clocks.** There is no soft-delete concern and no `deleted_at`. Every table declares `:prose`, `:skeleton` or `:authored`; soft deletion would make Retention's two periods decorative.
- **SQLite, so the schema stays portable**: no PostgreSQL enums and no PG-specific JSONB operators. Postgres is deferred on cost, not rejected.
- **Invariants live in the database wherever they fit in one** — a Second as a CHECK, an Exhibit playable once by unique index on the Case File row it is spent from, a shift landing once per document by a *partial* unique index over the receiving Side's Case File row — partial because `source_ref` names no source table and an Event's shift will point elsewhere — tenancy as composite foreign keys — and where the boundary is narrower than tenancy, the narrower key: an Exhibit rides and is spent out of its own Team's Case File because `staged_offer_exhibits` and `played_exhibits` reach their Side-scoped parents by `(id, side_id)` rather than by tenancy, which two Sides sharing a Simulation and an Organization would otherwise slip past. A Day is not Side-scoped, so it keeps the tenancy key — the rule is the narrowest key that says the thing, not `side_id` everywhere. A run's own tables key on `(parent_id, simulation_id, organization_id)`, not the Organization alone: a Section runs many concurrent Simulations, so the narrower key would permit a row pairing a Side from one run with a Day from another. Rules that span tables stay in Ruby.

## The LLM boundary

Dialogue is generated offline by a rake task and stored; the request path is pure Rails against stored rows. **The LLM client is never autoloaded into the web tier**, and the model never reads student prose — not for grading, not for summarizing, not as a safety pass. See `docs/adr/0001-stack-and-language.md`.

## The game view

Inertia + Svelte through Vite Ruby, per ADR 0001. `inertia_rails` installs onto no other bundler, and wires its asset version to `ViteRuby.digest`. Pages live in `app/frontend/pages`, resolved by the one entrypoint `app/frontend/entrypoints/inertia.js`; `bin/dev` runs Rails and the Vite dev server together off `Procfile.dev`.

**Svelte 5 runes only, and pre-2026 Svelte-Inertia idiom is confidently wrong.** `@inertiajs/svelte` 3.x requires Svelte `^5`: components take `$props()` rather than `export let`, use `{#snippet}` rather than slots, and read the current page off the adapter's exported `page` object — `{page.props.foo}` — because there is no `$page` store to auto-subscribe to.

SSR stays off. Turning it on means `plugin :inertia_ssr` in `config/puma.rb`, which is the one thing that would put a Node process in the request path — an ADR-level change, not a config tweak.

Node is build-time only. It appears in `assets:precompile` (enhanced by vite_ruby, never replaced), in `bin/vite dev`, and — since the suite began rendering a screen — in CI's `test` job, which installs `node_modules` because a request spec goes through the layout and `autoBuild` then builds the bundle. That is a build at test time rather than a Node process in the request path, which is the boundary ADR 0001 actually draws. `e2e` has no Node: no Cucumber scenario renders a view yet, and the first one that does will fail loudly rather than quietly. The pin lives in `.node-version`, mirrored in CI and the Dockerfile.

## The part set

`portraits/default` is committed art, not generated output: a directory of SVG fragments per group plus `set.yml`, which is the set's own statement of its groups, its weighting (a name listed twice is drawn twice as often) and its stacking order. Every shape carries a **tone level** — `t0` paper, `t4` ink, `t1`–`t3` the screens between — and never a colour, so a page can swap the whole portrait to a flat wash by moving four custom properties. A shape whose value fits no level is dropped rather than rounded.

The parts derive from `fangpenlin/avataaars` and stay **MIT** inside this Apache-2.0 repo; `portraits/default/NOTICE` carries the grant and has to travel with them. `rake portraits:derive[path/to/avataaars]` regenerates the whole directory and is **design-time only** — ADR 0008 forbids generating art at build, at import and at runtime alike, so never wire it into any of them. A commissioned set is proprietary, ships with the Cases and loads from `PORTRAIT_PART_SET`.

## Verification

```bash
bundle exec rspec       # specs
bundle exec cucumber    # features
```

`bin/rubocop` and `bin/brakeman` run automatically on every commit via pre-commit, so a clean commit means both passed. Run them directly only to see failures before committing.

Test gems are added when a ticket needs them rather than kept ahead of use, so reach for `factory_bot` or `timecop` by adding them, not by assuming they are there. Capybara, Selenium and axe are in, added with the first screen: Inertia renders in the browser, so a system spec drives a real one and axe has a DOM to read. They run by default — a suite that silently skipped its only screen would report green on a page nobody rendered — and Vite builds the bundle for them, which is what makes them the slow part. `SKIP_SYSTEM_SPECS=1 bundle exec rspec` opts out when the view is untouched.

Distinguish pre-existing test failures from ones your change introduced before reporting results.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `MattMencel/bizlaw`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
