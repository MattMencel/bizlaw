# CLAUDE.md

Engine for a two-team, asynchronous legal negotiation simulation used in college business law courses. Two student teams take opposing sides of one authored case and negotiate toward a settlement their client will accept, across a calendar of Days; an instructor runs sections, drives the clock and grades.

The engine is Apache-2.0 and lives here. Authored Cases are proprietary content and live in a separate private repository.

## State of the repository

Early. [#283](https://github.com/MattMencel/bizlaw/issues/283) stripped the previous Rails application — ruled throwaway by [Map #257](https://github.com/MattMencel/bizlaw/issues/257) — back to a Rails 8 skeleton on SQLite, and [#284](https://github.com/MattMencel/bizlaw/issues/284) laid the first tables on it: the authored Case, Version and calendar, and the run's Organization, Section, Simulation, Sides and Days. [#285](https://github.com/MattMencel/bizlaw/issues/285) gave a Day its two Budget halves and [#286](https://github.com/MattMencel/bizlaw/issues/286) the command seam that spends the preparation one, with the authored Action menu, the Docket and its re-fold trigger. [#287](https://github.com/MattMencel/bizlaw/issues/287) made those Actions land: the authored Clients, Terms and documents an Action yields, the Case File a landing fills, and the shift ledger a Client's bound is folded from. [#288](https://github.com/MattMencel/bizlaw/issues/288) closed the Day: the commitment ledger a Side declares itself finished in, the deadline an Instructor moves, and the one compare-and-set all three closers go through. [#289](https://github.com/MattMencel/bizlaw/issues/289) put an Offer on a Team's own table: the staged Offer over the Case's Terms vocabulary, the Second the Docket teaches by leaving a dead control in a lone student's hand, and the Instructor's waiver of it for one Team for one Day. `committed_offers` is created here and stays empty. Committing one arrives with the rest of [#282](https://github.com/MattMencel/bizlaw/issues/282)'s chain. `users` holds only what Attribution needs — there is no authentication, roster or Pairing yet. There are no rooms either; Inertia and Svelte are mandated by ADR 0001 for the game view but are deliberately not installed until there is one to render.

A Case is loaded through one seam, `Cases::Import`, from a YAML file — `db/cases/reference.yml` is the engine's own minimal reference Case, not authored teaching material. `rake case:import[path]` runs it. `Simulations::Create` is the only path that lays out a Simulation, `Days::Land` is the only path that materialises what an Action yielded, `Days::Close` is the only path that closes a Day — `Days::Commit`, `Days::FireDeadlines` and the Instructor's force-close all call it, and a second path that "also closes the Day" is the bug that shape exists to make impossible — `Days::Command` is the only writer to a Day's Budget and Docket ledgers — narrower than [#282](https://github.com/MattMencel/bizlaw/issues/282)'s seam paragraph, which put the Day commit and the Instructor's powers inside `Command` too; they sit beside it instead, because `Command`'s two verbs exist to confirm a spend and none of those three has a cost to confirm: every act enters through it with two verbs, `quote` — which computes the cost, the half, what is left today and the landing Day, writes nothing, and returns a refusal rather than raising — and `apply`, which performs it. The confirmation a student reads is rendered from `quote`, so add an act to that seam rather than beside it. `Offers::Stage` is the only path that puts a position on a Team's table, and it sits beside `Command` for the same reason `Days::Commit` does: staging costs nothing, so there is nothing to confirm. The Docket a teammate reads is `Docket`, a fold over the spend ledger, the staged Offers and the Instructor's waivers, because only the first of those is a spend.

`CONTEXT.md` is the domain glossary and the source of the vocabulary the code should use. Read it before naming anything.

## Conventions that differ from Rails defaults

These come from `docs/adr/0002-runtime-schema.md`, and getting them wrong produces migrations and queries that look correct but aren't:

- **Everything that moves is an append-only ledger, derived on read.** Action Budget remaining, a Client's reservation point, bound consumed, Reaction Band, Case File membership, Exhibit spent-state and Simulation status are folds over rows, not columns. There is no status column anywhere. It is not event sourcing — ordinary Rails tables, no projections, no replay.
- **`day_budgets`'s spent counters are the one materialized exception** — a preparation pair and an exchange pair in one row, each carrying `CHECK (spent <= budget)` and maintained by an `AFTER INSERT` trigger on `docket_entries` that re-folds the sum rather than incrementing it. Adding a second materialized aggregate needs an ADR, not a migration.
- **The rule for a ceiling is what it does when reached.** A ceiling that refuses gets a database CHECK; a ceiling that saturates gets a value computed by the model. The Client's bound saturates, so it is never a CHECK — one placed there would crash on a legal play.
- **`schema_format` is `:sql` and the repo tracks `db/structure.sql`.** Triggers do not survive a `schema.rb` dump. `spec/schema_format_spec.rb` proves the format still round-trips one.
- **Deletion is hard deletion, on Retention's clocks.** There is no soft-delete concern and no `deleted_at`. Every table declares `:prose`, `:skeleton` or `:authored`; soft deletion would make Retention's two periods decorative.
- **SQLite, so the schema stays portable**: no PostgreSQL enums and no PG-specific JSONB operators. Postgres is deferred on cost, not rejected.
- **Invariants live in the database wherever they fit in one** — a Second as a CHECK, an Exhibit playable once by unique index, a shift landing once by unique index on its source, tenancy as composite foreign keys. A run's own tables key on `(parent_id, simulation_id, organization_id)`, not the Organization alone: a Section runs many concurrent Simulations, so the narrower key would permit a row pairing a Side from one run with a Day from another. Rules that span tables stay in Ruby.

## The LLM boundary

Dialogue is generated offline by a rake task and stored; the request path is pure Rails against stored rows. **The LLM client is never autoloaded into the web tier**, and the model never reads student prose — not for grading, not for summarizing, not as a safety pass. See `docs/adr/0001-stack-and-language.md`.

## Verification

```bash
bundle exec rspec       # specs
bundle exec cucumber    # features
```

`bin/rubocop` and `bin/brakeman` run automatically on every commit via pre-commit, so a clean commit means both passed. Run them directly only to see failures before committing.

Test gems are added when a ticket needs them rather than kept ahead of use, so reach for `factory_bot`, `timecop` or `capybara` by adding them, not by assuming they are there.

Distinguish pre-existing test failures from ones your change introduced before reporting results.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `MattMencel/bizlaw`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
