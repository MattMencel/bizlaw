---
status: accepted
---

# The register is the paper, and there are no rooms

[#299](https://github.com/MattMencel/bizlaw/issues/299) built three mocks of one
negotiation beat and compared them as *registers* — the visual idiom the game is
drawn in. **The paper won.** The game is the file: letterhead, an Exhibit as a
tab clipped to a draft, a redlined term sheet with the Client's aspiration in
the margin, service as a stamp, the Second as a countersignature block with one
line signed and one blank naming who may sign, and a docket that is a docket.
Exactly **one** face survives — the Team's own Client, where the Reaction Band
lands, and nowhere else.

This ADR records that decision rather than making it, because #299 closed
without one and the repo's own glossary went on describing the thing it
replaced. The decision is hard to reverse — it cancels an art commission and
sets the shape of every surface — and it is surprising without context, because
a negotiation game with no negotiating table is not what a reader expects to
find.

The deciding argument is what the room turned out to be *doing*. Every carrier
the beat required except one — the Offer, the Exhibits riding it, the single
price, the Docket, the Terms Board — landed in a panel drawn *over* the room,
because none of them is a thing a face can say; opening the Terms Board covered
the room entirely. So the room carried the Reaction Band and nothing else, and
the Band is two-valued. That is a commission sized for eight expression states,
bought to render two. The paper needed no such panel: every carrier already had
a legal-stationery form, and not one of them needed a legend.

## Considered options

**The Boardroom, as [#267](https://github.com/MattMencel/bizlaw/issues/267)
scoped it.** Bust reskin, business dress, a faked table, two figures angled
across it, the Team's own Client large in the near foreground. It reads; the
mock is not a failure of execution. It lost on the paragraph above — roughly 52
parts of commissioned art whose only live job was one bit of signal.

**The Console.** A terminal register: phosphor on black, monospace, box-drawn
panels, the cast at 44px. The scene cost genuinely evaporates — no table, no
three-quarter view, no hands. It lost to its own mock: at that size the `FIRM`
chip beside the bust carried the Band and the bust did not, so the portraits
were decoration still authored per Case. Low-contrast phosphor on a classroom
projector is also the wrong answer to the accessibility constraint that decided
ADR 0001.

**The paper with no face at all.** Cheaper still, and every mechanic survives it.
Rejected on the pitch rather than the play: faces sell the course to a
professor, so buy exactly one, and put it where the Band actually lands.

## Consequences

**Deleted as concepts, not merely unbuilt:** the Firm, the Boardroom, the
conference table, the opposing busts, the door between the rooms, the two-room
grammar, and the Close-up. `CONTEXT.md` described all of them and is corrected
alongside this ADR. Of the four authored Parties, exactly one — a Team's own
Client — is ever portrayed; the other three are named in prose and never drawn,
which is what the opposing Client and both counsel now are.

**The act-distinction survives the place-distinction.** Preparation is still
ungated and an Offer still commits at most once per Side per Day over a
teammate's Second. What carried that difference was two rooms; what carries it
now is the instrument — you spend from the Action Board, and you execute a draft
over a countersignature. Nothing in the schema moves, because none of it ever
encoded a room.

**The room vocabulary outlives this ADR in the code, and that is deliberate.**
`CONTEXT.md` is corrected here because it is the glossary every session is told
to read first; everything below is left for the change that actually touches
the behaviour, and this ADR is what makes each of those a correction rather
than a regression.

What still says *room* and should stop:

- **The Morning Briefing's own copy.** `app/reads/morning_briefing.rb`'s
  `two_room_line` and `config/locales/reads.en.yml` still tell a student to
  "Prepare in the Firm and deal in the Boardroom" — copy for two rooms that do
  not exist — asserted by `spec/reads/morning_briefing_spec.rb` and
  `features/step_definitions/morning_briefing_steps.rb`, and described in
  `features/morning_briefing.feature`'s own prose. The line the Briefing names
  is now the Day's grammar, not the rooms.
- **Six implementation comments** that use *Boardroom* as a live word for the
  commit act or for the surface that calls a seam: `app/models/side.rb`,
  `app/models/docket_entry.rb`, `app/services/days/command.rb` (twice),
  `app/services/offers/stage.rb`, `app/services/offers/accept.rb`. The
  constraint each one explains is unchanged; only the word for it is wrong.
  `features/commit_the_offer.feature` and two specs carry the same word.
- **`README.md` and `CLAUDE.md`.** Both describe the game view as a *room* to
  be rendered. `CLAUDE.md` is the worse of the two, because it also says "there
  are no rooms either" in the sense of *not built yet*, and after this ADR that
  sentence reads as agreement when it is a different claim entirely.

What keeps the word, correctly:

- **ADR 0001** and the migrations under `db/migrate/`. Both are records of what
  was decided or done at a point in time, and editing them to match a later
  decision would destroy the thing they exist to preserve. ADR 0001's
  Inertia paragraph is narrowed by the consequence below, not rewritten.
- **`docs/design/avatar-systems.md`**, a survey written to inform
  [#267](https://github.com/MattMencel/bizlaw/issues/267). It is evidence, not
  guidance.

**ADR 0001's justification for Inertia is narrowed and should be revisited on
its own.** It rejected Hotwire because "a stateful boardroom with reacting
avatars and a Terms board is precisely where Hotwire is weakest". The boardroom
and the reacting avatars are gone, and what remains is a file of documents — much
closer to Hotwire's strength than to Inertia's. The stack is not reopened here,
and the accessibility argument that ruled out canvas engines is *strengthened*
by a register made entirely of text. But the next session to touch the game view
should ask the question before running the installer, not after.

**The commission changes kind.** One portrait in two Reaction Bands, plus
typography, texture and stamps, in place of #267's per-Case cast. What that one
face looks like is [#316](https://github.com/MattMencel/bizlaw/issues/316), and
what a Consult hands it back on is
[#314](https://github.com/MattMencel/bizlaw/issues/314); both are open, and this
ADR deliberately settles neither.

The mocks are the primary source:
[`prototype/three-registers`](https://github.com/MattMencel/bizlaw/tree/prototype/three-registers),
`prototype/art-registers/index.html`. The grammar drawn in the winning register
is [`prototype/day-grammar-paper`](https://github.com/MattMencel/bizlaw/tree/prototype/day-grammar-paper).
