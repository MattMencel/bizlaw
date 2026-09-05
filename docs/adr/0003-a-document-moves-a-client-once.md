---
status: accepted
---

# A document moves a Client once

Both Sides draw on one bound per Client, and two different acts can spend it
with the same authored document. A Team that buys `request_documents` finds the
personnel file, which is unfavorable to them, and the shift lands at the moment
of discovery. The other Team may hold that same file and play it as an Exhibit
riding a committed Offer, and where the Offer touches the Terms it bears on,
nothing relates the two acts: a second shift would land against the same
Client's same bound.

The ledger records **one** movement for that document. `client_shifts` keys both
kinds to the receiving Side's own `case_file_documents` row — the row the finder
filled, or the row service wrote — so an unfavorable discovery and a played
Exhibit over one document share a key, and a partial unique index refuses the
second:

```
UNIQUE (side_id, source_ref)
  WHERE source_kind IN ('unfavorable_discovery', 'exhibit_played')
```

A memorandum does not persuade a Client twice. Letting both land would make a
document worth double whenever both Teams happened to buy the same Action, and
Par is authored as what a Side that used its Exhibits should get: a shift
inflated by the *opposing* Team's diligence grades one Side on the other's
choices. That is the same objection that keeps Settlement Quality's floor
immobile.

## Considered options

Letting both land was the cheap alternative, and it is not obviously wrong — the
bound caps total travel either way, so nothing overflows. It fails on
comparability rather than on arithmetic: two Sections playing identically
diligent Teams get different Client positions depending on whether their Action
purchases happened to overlap.

A `source_table` column would have made the index plain rather than partial. It
invents a discrimination nothing yet needs, and the ledger currently has exactly
one source table.

## Consequences

The index is partial because `source_ref` carries no source table. These two
kinds point at `case_file_documents`; an Event's shift will point somewhere
else, and a plain `UNIQUE (side_id, source_ref)` would refuse an Event whose row
id collided with a Case File row's. Whoever builds the Event Deck declares its
own rule rather than inheriting this one by accident.

`Days::Land` checks the ledger before writing an unfavorable discovery rather
than letting the index catch it. `create_or_find_by!` retries its `find_by!` on
the attributes it was handed, would not match the `exhibit_played` row already
there, and would raise `RecordNotFound` out of a Day open. The rule is this
ADR's, so it reads as the rule.
