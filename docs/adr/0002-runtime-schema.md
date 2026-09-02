---
status: accepted
---

# The runtime schema is an append-only ledger with derived state

A Simulation writes a lot while it is played — Actions spent, Offers committed,
Exhibits played, Clients moved, Days closed, lines spoken — and almost all of it
is a record students, instructors and grading disputes read back. Everything that
moves is therefore stored as **append-only rows and derived on read**: Action
Budget remaining, a Client's reservation point, bound consumed, Reaction Band,
Case File membership, Exhibit spent-state and Simulation status are all folds
over ledgers, not columns. There is no status column anywhere, and no
materialized aggregate except the one named below.

The volumes make this free rather than clever: a Simulation is 8–12 Days, a
handful of Actions per Day, four Parties and a few Exhibits. At that size a fold
is cheaper than the reconciliation spec a materialized value would need, and it
deletes the entire class of *the cached number disagrees with the log* bugs. It
is deliberately **not** event sourcing — ordinary Rails tables, no projections,
no replay machinery, nothing to review beyond the models themselves.

The ledger also happens to be the product. The Docket is a screen students read,
Attribution sits on every spend, and `docs/adr/0001-stack-and-language.md`'s
grading-dispute requirement means the trail has to exist regardless. Deriving
from it costs nothing that was not already being stored.

## The one materialized exception

`day_budgets`'s spent counters are materialized and carry
`CHECK (spent <= budget)`, because the Action Budget is the only value in the
game two humans race on and the only ceiling whose correct behaviour at the
boundary is a **refusal**. A constraint expresses refusal natively.

The Budget arrives in two halves that do not carry, and the halves are two
ceilings rather than one, so the exception is **two counter pairs in one row**,
each with its own CHECK:

```
day_budgets(side_id, day_id,
            preparation_budget, preparation_spent,
            exchange_budget,    exchange_spent)
  CHECK (preparation_spent <= preparation_budget)
  CHECK (exchange_spent    <= exchange_budget)
  UNIQUE (side_id, day_id)
```

The row is written when the Day opens and never recomputed, so a Section edit
mid-Simulation reaches later Days only and cannot rewrite a Day already played.

Both `spent` columns are maintained by an `AFTER INSERT` trigger on
`docket_entries` that **re-folds** the sum from the Docket rather than
incrementing it. A fold cannot drift the way a lost or doubled delta can, and a
trigger cannot be bypassed by an insert path added later that forgot to check —
which is the actual exposure, since SQLite serializes writers and had already
killed the race.

The Client's bound is the deliberate contrast, and the reason there is no second
counter. Its ceiling **saturates** rather than refusing: an Exhibit played into
an exhausted bound is still spent and still scores, with its shift clipped. A
CHECK cannot express that, and one placed there would crash on a legal play. So
`applied_fraction` is computed by the model, never supplied by the caller, with
`CHECK (abs(applied_fraction) <= abs(requested_fraction))` to make a forgotten
clip loud.

The rule that separates them is *what the ceiling does when you reach it* — a
ceiling that refuses gets a constraint, a ceiling that saturates gets a computed
value. Not *is there a race*, which was the wrong question in a database with one
writer.

## Consequences

**The schema format becomes `:sql`.** Triggers do not survive a `schema.rb` dump,
so `config.active_record.schema_format = :sql` and the repo tracks
`structure.sql`. Migration diffs get noisier; greenfield is the moment to pay
that rather than after fifty migrations.

**Invariants live in the database wherever they fit in one.** A Second is
`CHECK (seconded_by_user_id != staged_by_user_id)`. An Exhibit plays once by
unique index. A shift lands once by unique index on
`(side_id, source_kind, source_ref)`, which is what makes a double Day-open
harmless rather than merely improbable. Tenancy is composite foreign keys, so a
child cannot point at a parent in another Organization. The rules that span
tables — the waiver-or-Second gate — stay in Ruby, where the instructor UI has to
explain them anyway.

**Staged and committed Offers are separate tables**, so that every cross-Side
read targets one that structurally contains no live positions. The alternative
was one table where safety depended on remembering a predicate, and the leak it
guards is the opponent's current negotiating position — the worst one available.

**Scores derive until Release, then freeze.** Release writes immutable rows
carrying the number, the weights, the Par and any adjustment. A dispute a year
later is answered from a row rather than by re-running a year-old code path
against a scoring rule that has since changed.

**Day close is a compare-and-set**, `UPDATE days SET closed_at = ? WHERE id = ?
AND closed_at IS NULL`, and all three callers — the second Side's commit, the
deadline job and an Instructor force-close — go through it. Exactly one writer
gets an affected row and does the open work in the same transaction.
