# BizLaw

[![Ruby Code Style](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/standardrb/standard)

Engine for a two-team, asynchronous legal negotiation simulation used in college
business law courses. Two student teams take opposing sides of one authored case
and negotiate toward a settlement their client will accept, across a calendar of
Days at a firm. An instructor runs sections, drives the clock and grades.

## Status

Greenfield. The previous Rails application was ruled throwaway in
[Map #257](https://github.com/MattMencel/bizlaw/issues/257) and stripped in
[#283](https://github.com/MattMencel/bizlaw/issues/283); what is here now is a
Rails 8 skeleton on SQLite with `structure.sql` tracked. The engine's tables,
models and rooms arrive with
[#282](https://github.com/MattMencel/bizlaw/issues/282)'s chain.

## Stack

Ruby on Rails 8 on SQLite, with Solid Queue, Solid Cache and Solid Cable on the
same volume. Inertia and Svelte drive the game view and are installed when there
is a room to render. No LLM client runs in the web tier — NPC dialogue is
generated offline and stored.

Decisions of record are in [`docs/adr/`](docs/adr/); the domain vocabulary is in
[`CONTEXT.md`](CONTEXT.md).

## Getting started

```bash
bin/setup
```

Then:

```bash
bin/rails server
```

## Verification

```bash
bundle exec rspec
bundle exec cucumber
bin/rubocop
bin/brakeman
```

`bin/rubocop` and `bin/brakeman` also run on every commit through pre-commit.

## Licence

The engine is Apache-2.0; see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
Authored Cases are proprietary content and live in a separate private repository.
