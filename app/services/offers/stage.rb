# frozen_string_literal: true

module Offers
  # A Team member puts an Offer on the table for the Team to look at, or revises
  # the one already there. It is the same act either way: a revision replaces
  # the position rather than amending it, which is why there is one seam and not
  # two.
  #
  # It costs nothing and writes no Docket row, because nothing has been spent —
  # what the Docket shows is the staging itself, folded in on read.
  #
  # It refuses four things and only four: a settled run, a closed Day, a Day
  # that has not opened, and a Day this Team has already committed its Offer
  # on. The first two are the table being gone; the third is the table not
  # being laid yet; the fourth is the position already being taken.
  #
  # The closed Day and the committed one are held twice — once here, for the sentence, and once in the
  # database, for the race. Both are read before the transaction that writes, so
  # a Day closing or an Offer committing in that window passes the read and lands
  # on a trigger instead; `RACED_CLOSE` and `RACED_COMMIT` turn that back into
  # the same refusal, so one rule has one answer however the race fell out. See
  # the `..._an_unexecuted_day` migration for why the guard is in the database
  # rather than re-read inside the transaction.
  #
  # Terms are given as a Hash over the Case's authored vocabulary, mapping each
  # Term's key to money's amount in cents and every other Term to nil:
  #
  #   Offers::Stage.call(side:, day:, by:, terms: {"money" => 45_000_00, "apology" => nil})
  #
  # A key the Case does not author is a caller with a vocabulary the engine
  # never offered, not a refusal a student should see, so it raises.
  #
  # `exhibits:` are the Case File rows riding the Offer, and they are part of
  # the position for the same reason the Terms are: the teammate who Seconds is
  # confirming the whole play, so a set of Exhibits chosen at the commit control
  # would let them play cards the member who took the position never proposed.
  # Any number may ride one Offer; they cost nothing until it commits.
  class Stage
    # The two rules this seam refuses that a database trigger also holds, and the
    # triggers' own names. Each check here is made **before** the transaction
    # that writes, so a Day closing or an Offer committing in that window slips
    # past it and lands on the trigger instead — the ordinary two-tab case rather
    # than a fault, since the other Side closes the Day by committing and a
    # teammate executes the draft from a second seat.
    #
    # So the fault is turned back into the refusal this seam already names, the
    # way `Days::Command` turns its own raced ceilings back into quotes. A caller
    # gets one answer for one rule however the race fell out, and a student gets
    # the sentence rather than a 500.
    #
    # Anything else out of the database is a fault and is not caught.
    RACED_CLOSE = Regexp.union(
      "staged_offers_need_an_unclosed_day",
      "staged_offer_terms_need_an_unclosed_day",
      "staged_offer_terms_stay_on_an_unclosed_day",
      "staged_offer_exhibits_need_an_unclosed_day"
    )
    RACED_COMMIT = Regexp.union(
      "staged_offers_need_an_unexecuted_day",
      "staged_offer_terms_need_an_unexecuted_day",
      "staged_offer_terms_stay_on_an_unexecuted_day"
    )

    def self.call(...) = new(...).call

    def initialize(side:, day:, by:, terms:, exhibits: [], note: nil)
      @side = side
      @day = day
      @by = by
      @terms = terms
      @exhibits = exhibits
      @note = note
    end

    def call
      # A settled run has nothing left to put a position in front of. Staging
      # into one would be a draft against a table that has been cleared.
      if day.simulation.settled?
        raise Simulation::AlreadySettled, "this Simulation has already settled"
      end

      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

      # `Day#open?` is only `closed_at IS NULL`, so every unplayed Day passes
      # the check above; what marks a Day as reached is its Budget, the same
      # thing `Days::Command` and `Offers::WaiveSecond` ask. A draft left
      # waiting on a later Day is read for playability only now, so an Exhibit
      # riding it could be spent on the Day before and the draft would arrive
      # holding a card that is already gone.
      #
      # No trigger backs this one. The triggers here catch a Day changing
      # between the read and the write, and a Day's Budget is never taken away
      # — a Day opening in that window only makes the write legal.
      raise DayNotOpen, "Day #{day.ordinal} has not opened yet" if side.budget_on(day).nil?

      # A Team commits at most one Offer a Day, so a Day whose Offer is committed
      # has no second position to put on the table — and revising the draft it
      # was copied from would leave the executed instrument printing terms that
      # were never signed, `TermsBoard#ours` preferring the draft to the
      # committed Offer. The Day stays open until the other Side commits, so this
      # window is real rather than theoretical.
      #
      # This and the Day above are both read before the transaction below, so
      # neither is the last word: a commit or a close landing in that window is
      # caught by the trigger and turned back into this same refusal — see
      # `RACED_COMMIT`. What this pair is for is answering without a failed write
      # in the ordinary case, which is every case but the race.
      if side.committed_offer_on(day)
        raise AlreadyCommitted, "this Team has already executed an Offer on Day #{day.ordinal}"
      end

      vocabulary = terms_authored_for(terms.keys)
      riding = exhibits_held_for_play

      ActiveRecord::Base.transaction do
        # Keyed by id rather than by object, so that the insert this loses to a
        # teammate staging at the same moment leaves nothing half-built hanging
        # off the Side's association for the next read to trip over.
        offer = StagedOffer.create_or_find_by!(side_id: side.id, day_id: day.id) do |row|
          row.staged_by_user_id = by.id
        end
        # `staged_by` is who staged it and does not move. The Second is
        # measured against the member who put the Offer on the table — a
        # revision revises a position that is already there, and moving the
        # Attribution with it would quietly erase the one member the gate is
        # defined against.
        offer.update!(note: note)
        offer.offer_terms.destroy_all
        terms.each do |key, amount_cents|
          offer.offer_terms.create!(
            case_term: vocabulary.fetch(key.to_s), amount_cents: amount_cents
          )
        end
        # An Exhibit riding the Offer is part of the position, so a revision
        # replaces the set rather than adding to it — the same rule the Terms
        # above follow, and for the same reason.
        offer.offer_exhibits.destroy_all
        riding.each { |filed| offer.offer_exhibits.create!(case_file_document: filed) }
        offer.reload
      end
    rescue ActiveRecord::StatementInvalid => e
      raise DayClosed, "Day #{day.ordinal} has already closed" if RACED_CLOSE.match?(e.message)

      if RACED_COMMIT.match?(e.message)
        raise AlreadyCommitted, "this Team has already executed an Offer on Day #{day.ordinal}"
      end

      raise
    end

    private

    attr_reader :side, :day, :by, :terms, :exhibits, :note

    # An Exhibit rides an Offer out of this Team's own Case File, and only one
    # the Team can actually play. A document carrying no Exhibit, one pointing
    # at this Team's own Client, one already spent, or one out of somebody
    # else's folder is a caller with a menu the engine never offered rather than
    # a refusal a student should see — the draft reads playability off the
    # Case File before it offers the control.
    def exhibits_held_for_play
      exhibits.each do |filed|
        next if this_team_can_play?(filed)

        named = filed.is_a?(CaseFileDocument) ? filed.title.inspect : filed.inspect
        raise ArgumentError, "#{named} is not an Exhibit this Team holds to play"
      end

      # An Exhibit rides an Offer once, and the unique index underneath says so
      # too. The Terms cannot be named twice because they arrive as a Hash;
      # these arrive as a list, so the seam has to. Without it a doubled control
      # press comes back as a database fault rather than as this seam's own
      # refusal, which is the one thing every other bad menu here gets.
      return exhibits if exhibits.map(&:id).uniq.size == exhibits.size

      raise ArgumentError, "an Exhibit rides an Offer once, and one is named twice"
    end

    def this_team_can_play?(filed)
      filed.is_a?(CaseFileDocument) && filed.side_id == side.id && filed.playable?
    end

    # An Offer naming no Term at all is not a position. A Team that wants
    # nothing on the table discards.
    def terms_authored_for(keys)
      raise ArgumentError, "an Offer names at least one Term" if keys.empty?

      vocabulary = side.case_version.terms.index_by(&:key)
      unknown = keys.map(&:to_s) - vocabulary.keys
      return vocabulary if unknown.empty?

      raise ArgumentError,
        "#{unknown.join(", ")} is not on this Case's Terms vocabulary"
    end
  end
end
