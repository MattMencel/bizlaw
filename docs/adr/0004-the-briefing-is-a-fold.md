---
status: accepted
---

# The Morning Briefing is folded on read

[#282](https://github.com/MattMencel/bizlaw/issues/282) says the Day's close
composes the Morning Briefing, in the same transaction that writes the next
Day's Budget quota and materialises what landed. ADR 0002 says the opposite for
everything that moves: it is derived on read, with `day_budgets`' two spent
pairs as the single named materialized exception, and a second one needs an ADR
rather than a migration.

This is that ADR, and it goes the other way. There is no briefing row. A
briefing is a fold over rows that already exist — the Case File rows this Day's
open landed, the rows the other Side's service wrote, the documents in hand at
the open, and the Case's own opening statement, calendar and published Rubric.

The deciding argument is not the exception rule but the absent teammate. The
briefing a student reads on Day 5 and the one a teammate returning from Day 2
reads are the same object over different ranges of the same rows. A row written
at close can only answer one of the two, so a composed briefing needs a fold
beside it for the other — and then the design has both a materialized aggregate
and the fold it can disagree with, which is the failure ADR 0002's rule exists
to prevent. Widening is a parameter, `since:`, and never a per-student record:
CONTEXT's Onboarding section rules out per-student progress state, and deriving
the range from Attribution would reinvent it — a teammate who deliberated all
week but spent nothing would read as absent, and one who spent once on Day 2
would be caught up on Days 3 through 7 forever.

## Considered options

**Composing at close, as #282 describes.** Its appeal is that a briefing is read
far more often than a Day closes, and the composition touches four sources. The
cost is a table whose rows are a snapshot of other tables — the shape ADR 0002
calls out — plus the fold above for the absent teammate, and a Day 1 briefing
that no close ever ran for.

**Caching the fold behind a memoized read.** Cheaper than a table and it keeps
one source of truth. It buys nothing yet: nothing here is measured as slow, and
the request path is a handful of indexed reads against one Side's own rows.

## Consequences

`Days::Close` keeps the two things it already does and gains nothing. #282's
Day-close paragraph is superseded on this one line; the rest of it stands.

The read objects live in `app/reads/`, and the Docket — the first fold built,
which sat in `app/models/` for want of anywhere better — moves there with them.
They carry CONTEXT's own names, unnamespaced: `Docket`, `CaseFile`,
`ActionBoard`, `TermsBoard`, `MorningBriefing`. A directory holding nothing but
folds is also what the two absence specs point at, which is what keeps them from
having to glob all of `app/` as it grows.

The `since:` parameter is the only widening. A caller that wants the Days a
teammate missed decides which Days those are; the briefing does not guess.
