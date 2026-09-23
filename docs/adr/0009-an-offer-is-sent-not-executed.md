---
status: accepted
---

# An Offer is sent, not executed

[ADR 0005](0005-the-register-is-the-paper.md) moved the act-distinction from
two rooms onto the instrument and named the act that makes an Offer
**executing a draft**. The copy followed it: "Execute this draft", "Executed the
draft" in the Docket, an "Executed" mark on a term sheet nobody has accepted,
"Executed by" heading a draft's signature block. That word is wrong at law, and
[What does sending an Offer get called, if not "execute"?](https://github.com/MattMencel/bizlaw/issues/392)
replaces it. Everything else in ADR 0005 stands.

To execute an instrument is to sign it so it binds. An offer binds nobody. It
gives the other side a power of acceptance, and it exists only once they have
it (Restatement (Second) of Contracts §§23–24, 35; only acceptance concludes the
bargain, §50). So the game used one word, and one stamp, for a revocable
proposal and for the settlement contract, and a student who saw "Executed" on
their own term sheet on Day 3 could fairly think a deal existed. The
[legal-accuracy research](https://github.com/MattMencel/bizlaw/blob/research/copy-legal-accuracy/docs/research/copy-legal-accuracy.md)
ranks it a real error, and the
[copy audit](https://github.com/MattMencel/bizlaw/blob/research/copy-audit/docs/research/copy-audit.md)
found the same act called *execute* in one block and *commit* in the next.

## Decision

**An Offer is sent.** Each stage of its life has one word, and no stage borrows
a later one's:

- **Draft** — staged, seen by the drafting Team only. It is not *on the table*:
  the other Side cannot see it, and an offer they cannot see is no offer.
- **Sent** — the act that makes it an Offer, gated by the Second. "Send this
  offer", "Sent an offer", and a "Sent · Day n" stamp. *On the table* is kept
  for a sent Offer only, where it is accurate.
- **Accepted** — the other Side takes it.
- **Executed** — the accepted instrument, and nothing earlier. "Executed on
  Day n", "Executed by" and the execution stamp live there alone.

The draft's signature block is headed **Signed by**, since signing an offer
before sending it is ordinary and accurate. A blank line reads "Waiting on a
countersignature from: …", and "Countersigned by" appears only once somebody
has signed.

**Commit** now names the Day alone, in the glossary and in copy. A Side commits
its Day; it sends an Offer.

## Considered options

**Extend.** The term of art, and a word the course would teach. But it needs a
gloss wherever it appears, and "Extend this offer" is stiff on a button that an
undergraduate who skims has to understand at a glance.

**Make.** Accurate, and weak on a control.

**Sign and send.** It covers the countersignature as well, but it puts two acts
under one label, and the Second is already carried by the block above the
button.

**Keep *commit* as the glossary word and use *send* only in the copy.** Rejected
because copy takes its vocabulary from `CONTEXT.md`
([voice rule 3](../design/voice.md)), so a copy-only word would drift back. It
would also leave *commit* naming two acts, the Offer and the Day.

## Consequences

- **`CONTEXT.md`** says *sent* wherever it said *committed* or *executed* of an
  Offer: § Party, § Day, § Offer, § Acceptance, § Second, § Exhibit, § Register, § Terms Board,
  § Morning Briefing's grammar, § Student Prose and § Retention. It is corrected
  alongside this ADR.
- **ADR 0005's vocabulary is amended by this one and not edited.** "An Offer
  commits by executing a draft" and "you execute a draft over a
  countersignature" record what was decided then; read *send* for both.
- **[ADR 0007](0007-the-settlement-beat-is-the-executed-instrument.md) is
  untouched.** It uses *executed* for the accepted instrument, which is the
  correct home for the word. Its phrase for an Acceptance, "a countersignature
  on their instrument", uses *countersign* in a second sense. That belongs to
  [One name for each concept](https://github.com/MattMencel/bizlaw/issues/400),
  not here.
- **Code identifiers keep *commit*.** `offer_committed`, `Days::Commit`, "the
  Offer commit" in `CLAUDE.md` and the specs are developer vocabulary, which
  [the writing map](https://github.com/MattMencel/bizlaw/issues/384) leaves out of
  scope. The mismatch is known, the same way ADR 0005 left *room* in the code
  until the change that touched it.
- **The strings themselves change in the rewrite hand-off**,
  [Rank the rewrites and hand them off](https://github.com/MattMencel/bizlaw/issues/401),
  not in this ADR. The stage-by-stage table in the
  [voice spec](../design/voice.md) is what they are checked against.
