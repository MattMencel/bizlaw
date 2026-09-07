---
status: accepted
---

# A Reaction Band is folded as of the spend

A Consult buys the one read a Team ever gets on how far its own Client has
moved. It yields no paper — the Client answers rather than the file — so the
only thing it writes is its `docket_entries` row, and that row is on the record
forever. A Team that consulted on Day 3 can read the line again on Day 5, and
what it should read then is what the Client said on Day 3. A band that moves is
shown at the next Consult, not the moment it moves; a Docket that re-reads live
is a free band ticker, and knowing where you stand is the thing an Action was
charged for.

The band is **folded as of the spend's own `created_at`**, against
`client_shifts.created_at`, and nothing is stored. `Side#reaction_band(as_of:)`
sums the ledger up to that instant, compares the fraction consumed to the
Client's authored edge, and answers *firm* or *ready*. It is the same fold as
`Side#bound_consumed` with a horizon on it.

## Considered options

**Storing the band on `docket_entries`** is exact and needs no time-travel. It
is also a second materialized aggregate, and the schema has exactly one —
`day_budgets`' spent counters, which earned it by being re-folded under a
trigger on every insert and carrying a CHECK. A band has neither, and a
`band` column read back is indistinguishable from the status column ADR 0002
spent its length refusing.

**Folding as of the spend's Day** is the obvious cheap horizon and is wrong.
Lead-zero discoveries land mid-Day and the opposing Team's Exhibits arrive on a
commit, so a Day 3 memo would keep changing for the rest of Day 3 — frozen in
name, live in fact, and worse than either honest option because the leak is
invisible.

## Consequences

Two rows written inside one transaction share a timestamp, so a shift and a
Consult committed together are order-ambiguous. No seam writes both: a Consult
is charged through `Days::Command` and shifts land in `Days::Land` and
`Exhibits::Play`. Whoever first writes a shift and a spend in one transaction
inherits this and declares its own tiebreak.

`Docket::Entry` widens to carry the Action's `kind` and the band, nil on the
three acts that have no cost — the Client's beat is emphasis and never the sole
carrier, and a Consult yields no document, so the Docket line is the only place
the band can also land. The Entry did not name the Action at all before this,
which is a gap independent of the band: a record of *what we have done* that
cannot say what was bought is not answering its own question.

The Morning Briefing needs no guard. Its landed section folds over held
documents and a Consult produces none, so a band cannot reach a free morning
read by accident.
