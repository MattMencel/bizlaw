---
sidebar_position: 1
---

# BizLaw

A two-team, asynchronous legal negotiation simulation for college business law
courses. Two student teams take opposing sides of one authored case and negotiate
toward a settlement their client will accept, across a calendar of Days at a firm.
An instructor runs sections, drives the clock and grades.

## Status

The engine is being rebuilt. The previous Rails application was ruled throwaway in
[Map #257](https://github.com/MattMencel/bizlaw/issues/257), and
[#283](https://github.com/MattMencel/bizlaw/issues/283) stripped the repository
back to a Rails 8 skeleton on SQLite. There is no running application to document
yet, so this site is deliberately close to empty — user documentation returns when
there are rooms to describe.

## Where the design lives

Three records in the repository carry the design, and none of them is published
here yet:

- **`CONTEXT.md`** — the domain glossary. What a Day, an Action Budget, an Offer, a
  Docket, an Exhibit and a Reaction Band each mean, written as the vocabulary the
  code is expected to use.
- **`docs/adr/`** — the decisions of record. ADR 0001 fixes the stack and language;
  ADR 0002 fixes the runtime schema as an append-only ledger with derived state.
- **`docs/design/`** and **`docs/rubric.md`** — research findings on avatar systems
  and browser stacks, and the grading rubric carried over from the old
  application.
