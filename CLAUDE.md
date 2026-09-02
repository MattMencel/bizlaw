# CLAUDE.md

Engine for a two-team, asynchronous legal negotiation simulation used in college business law courses. Two student teams take opposing sides of one authored case and negotiate toward a settlement their client will accept, across a calendar of Days; an instructor runs sections, drives the clock and grades.

The engine is Apache-2.0 and lives here. Authored Cases are proprietary content and live in a separate private repository.

## State of the repository

Greenfield. [#283](https://github.com/MattMencel/bizlaw/issues/283) stripped the previous Rails application — ruled throwaway by [Map #257](https://github.com/MattMencel/bizlaw/issues/257) — back to a Rails 8 skeleton on SQLite. There are no engine tables, models or rooms yet; they arrive with [#282](https://github.com/MattMencel/bizlaw/issues/282)'s chain. Inertia and Svelte are mandated by ADR 0001 for the game view but are deliberately not installed until there is a room to render.

`CONTEXT.md` is the domain glossary and the source of the vocabulary the code should use. Read it before naming anything.

## Conventions that differ from Rails defaults

These come from `docs/adr/0002-runtime-schema.md`, and getting them wrong produces migrations and queries that look correct but aren't:

- **Everything that moves is an append-only ledger, derived on read.** Action Budget remaining, a Client's reservation point, bound consumed, Reaction Band, Case File membership, Exhibit spent-state and Simulation status are folds over rows, not columns. There is no status column anywhere. It is not event sourcing — ordinary Rails tables, no projections, no replay.
- **`day_budgets.spent` is the one materialized exception**, carrying `CHECK (spent <= budget)` and maintained by an `AFTER INSERT` trigger on `docket_entries` that re-folds the sum rather than incrementing it. Adding a second materialized aggregate needs an ADR, not a migration.
- **The rule for a ceiling is what it does when reached.** A ceiling that refuses gets a database CHECK; a ceiling that saturates gets a value computed by the model. The Client's bound saturates, so it is never a CHECK — one placed there would crash on a legal play.
- **`schema_format` is `:sql` and the repo tracks `db/structure.sql`.** Triggers do not survive a `schema.rb` dump. `spec/schema_format_spec.rb` proves the format still round-trips one.
- **Deletion is hard deletion, on Retention's clocks.** There is no soft-delete concern and no `deleted_at`. Every table declares `:prose`, `:skeleton` or `:authored`; soft deletion would make Retention's two periods decorative.
- **SQLite, so the schema stays portable**: no PostgreSQL enums and no PG-specific JSONB operators. Postgres is deferred on cost, not rejected.
- **Invariants live in the database wherever they fit in one** — a Second as a CHECK, an Exhibit playable once by unique index, a shift landing once by unique index on its source, tenancy as composite foreign keys. Rules that span tables stay in Ruby.

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
