# CLAUDE.md

Legal education simulation platform for college business law courses: students work in teams on legal case simulations (primarily sexual harassment lawsuit negotiations), with instructors running concurrent simulations per case.

## Architecture

Hybrid API/web application — the same domain is served both as versioned JSON:API endpoints under `/api/v1/` and as traditional Rails views. Business logic lives in service objects under `app/services/` rather than in models or controllers.

## Conventions that differ from Rails defaults

These are not guessable from the framework, and getting them wrong produces migrations and queries that look correct but aren't:

- **UUID primary keys** for all major entities — never write an integer-PK migration.
- **Soft deletion** via the `SoftDeletable` concern. Deleting a record means setting `deleted_at`, and default scopes exclude soft-deleted rows; a query that must see them has to opt in.
- **PostgreSQL enums** back status fields, so adding a status value requires a migration, not just a constant.
- **JSONB metadata columns** hold flexible per-case data (`plaintiff_info` / `defendant_info` on `Case`).

Leverage the existing patterns rather than introducing new architectural approaches.

## Development

```bash
bin/dev    # Rails + Tailwind watch via Foreman (Procfile.dev)
```

Standard Rails and RSpec invocations work as expected. Two non-obvious ones:

```bash
bundle exec rspec --tag accessibility   # axe-core WCAG 2.0/2.1 AA specs only
bundle exec rspec spec/e2e/             # Playwright-driven end-to-end specs
```

System tests are RSpec under `spec/system/`, not Minitest — `rails test:system` runs nothing.

## Verification

Run the suites that cover what you changed, then the linters:

```bash
bundle exec rspec spec/models/     # model changes
bundle exec rspec spec/requests/   # API changes
bundle exec rspec spec/system/     # UI changes
bundle exec cucumber               # feature/behavior changes
```

`bin/rubocop` and `bin/brakeman` run automatically on every commit via pre-commit, so a clean commit means both passed. Run them directly only to see failures before committing.

Distinguish pre-existing test failures from ones your change introduced before reporting results.

## Project documentation

- `.prd/` — product requirements documents
- `.cursor/` — task lists and project planning

## Agent skills

### Issue tracker

Issues live as GitHub issues in `MattMencel/bizlaw`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary — `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context — `CONTEXT.md` and `docs/adr/` at the repo root, both created lazily. See `docs/agents/domain.md`.
