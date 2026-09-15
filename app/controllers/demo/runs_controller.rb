# frozen_string_literal: true

module Demo
  # The demo's one screen. The URL names a run and a seat, and the seat is
  # optional: #332 settled that the player is the plaintiff, alone, so the bare
  # form is his and the two seeded runs resolve to the Day each was laid down to
  # open on without anything to choose between.
  #
  # The seat is what the second tab needs. There is no authentication, no
  # session and no `Current.user`, and every seam in the Day takes a `by:` — so
  # the address is the whole of what says who is reading, and `Demo::Seat`
  # answers it. Nothing is held between requests: the pair is resolved from the
  # URL each time, which is why two tabs can be two people without either one
  # standing on the other.
  class RunsController < SeatedController
    def show
      seated = resolve
      return if performed?

      return executed(seated) if seated.side.simulation.settled?

      render inertia: "Demo/WorkingDraft",
        props: WorkingDraft.for(
          seated.side,
          day: sitting_day(seated.side.simulation),
          you: seated.user,
          refused: refusal_for(SPEND_REFUSAL, seated),
          draft_refused: refusal_for(DRAFT_REFUSAL, seated)&.fetch("reason"),
          commit_refused: refusal_for(COMMIT_REFUSAL, seated)&.fetch("reason"),
          acceptance_refused: refusal_for(ACCEPTANCE_REFUSAL, seated)&.fetch("reason")
        ).to_props.merge(
          spend_path: spend_path(seated),
          offer_path: offer_path(seated),
          commit_path: commit_path(seated),
          acceptance_path: acceptance_path(seated)
        )
    end

    private

    # The settled run, on the same address. The instrument has not become a
    # different document — it has stopped being a draft — so the front is the
    # executed agreement and the back still turns to the Case File and the
    # Docket, which is what ADR 0007 means by the page the file rests on.
    #
    # **It asks for no Day.** `sitting_day` answers *which Day is this Team in*,
    # and a settled run has no honest answer: `Days::Close` opens nothing after
    # an Acceptance, but `Simulations::Create` laid the whole calendar down at
    # the start, so the first unclosed Day is one that never opened — and the
    # page would render a live tomorrow with nil budgets and every Action
    # refused. `ExecutedInstrument` knows the Day from the Acceptance itself,
    # which is the only Day a settled run has left to name.
    #
    # There are no paths on it either. Nothing can be bought, drawn, executed or
    # taken, so a surface carrying an endpoint would be a control that cannot
    # exist looking for somewhere to post.
    def executed(seated)
      render inertia: "Demo/ExecutedInstrument",
        props: ExecutedFile.for(seated.side, you: seated.user).to_props
    end
  end
end
