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
| `app/controllers/api/`, serializers | `bundle exec rspec spec/requests/` |
| Views, Stimulus controllers, Tailwind | `bundle exec rspec spec/system/` |
| Behavior spanning a user story | `bundle exec cucumber` |
| Policies under `app/policies/` | `bundle exec rspec spec/policies/` |

UI changes additionally need `bundle exec rspec --tag accessibility` — this repo holds itself to WCAG 2.0/2.1 AA via axe-core, and that tag is the only thing that exercises it.

Establish which failures are pre-existing on `main` before attributing any to the PR.

`bin/rubocop` and `bin/brakeman` run under pre-commit, so a pushed commit has already passed both. Re-run them only when the PR touches the rubocop or brakeman config itself.

## Dependency updates

A green suite is necessary but not sufficient. Also confirm `bundle install` resolves cleanly, and read the release notes for behavior changes between the old and new version — Rails and Devise minor bumps in particular have changed defaults without changing any API this repo calls.

Per the repo's standing rule: fix transitive CVEs by bumping the direct dependency, never by pinning or forcing a transitive version.
