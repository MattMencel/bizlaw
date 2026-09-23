---
name: pr-review
description: Review a pull request against this repository's conventions. Use when reviewing a PR, a branch, or incoming changes in the bizlaw repo — covers which test suites to run for which kind of change, and what dependency-update PRs need beyond a green suite.
---

# Reviewing a pull request

## Setup

```bash
git fetch origin main:main
git checkout <pr-branch>
bundle install   # only if Gemfile.lock changed
```

Read the PR description and the commit messages before the diff — provenance explains intent, and a diff reviewed without it produces findings the author already considered.

## Which suites to run

Run the suites that cover the changed files, not the whole suite:

| Changed | Run |
|---|---|
| `app/models/` | `bundle exec rspec spec/models/` |
| `app/services/` | `bundle exec rspec spec/services/` |
| `app/reads/` | `bundle exec rspec spec/reads/` |
| `app/controllers/demo/`, `lib/demo/` | `bundle exec rspec spec/requests/ spec/demo/` |
| `app/frontend/`, views, `config/locales/reads.en.yml` | `bundle exec rspec spec/system/` |
| Migrations, `db/structure.sql` | `bundle exec rspec spec/schema/ spec/schema_format_spec.rb` |
| Behavior spanning a user story | `bundle exec cucumber` |

UI changes are held to WCAG 2.0/2.1 AA through `be_axe_clean` assertions inside the system specs, so `spec/system/` is what exercises it.

Establish which failures are pre-existing on `main` before attributing any to the PR.

`bin/rubocop` and `bin/brakeman` run under pre-commit, so a pushed commit has already passed both. Re-run them only when the PR touches the rubocop or brakeman config itself.

## Dependency updates

A green suite is necessary but not sufficient. Also confirm `bundle install` resolves cleanly, and read the release notes for behavior changes between the old and new version — Rails, `inertia_rails` and Vite Ruby minor bumps in particular have changed defaults without changing any API this repo calls.

Per the repo's standing rule: fix transitive CVEs by bumping the direct dependency, never by pinning or forcing a transitive version.
