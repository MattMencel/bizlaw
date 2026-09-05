# frozen_string_literal: true

module Exhibits
  # The Exhibits riding a committing Offer, played. The shift lands the moment
  # the Offer commits and the document reaches the other Side at that same
  # instant: playing an Exhibit *is* serving it.
  #
  # This is the seam `Days::Land` names — an Action's documents land through
  # that one, an Exhibit through this — and it runs inside the commit's own
  # transaction, so a Team is never charged for a play that half happened.
  #
  # Three rules decide what a played Exhibit is worth, and all three are
  # independent of whether it was worth playing:
  #
  # **Relevance.** It moves the Client only where the Offer touches a Term the
  # Exhibit bears on. A document arguing for reinstatement is worth nothing
  # attached to a cash-only Offer. An irrelevant Exhibit is still spent and
  # still served, and no shift row is written at all.
  #
  # **Clipping.** The shift saturates against the Client's remaining bound
  # rather than refusing — the arithmetic is `ClientShift`'s — so an Exhibit
  # played into an exhausted bound is still spent, still served, and clipped to
  # whatever travel remains. It scores regardless: a good argument put to a
  # Client who has already come around is still a good argument, and a Team
  # cannot see the bound it would be punished for missing.
  #
  # **Service.** The receiving Team is served the document and never its effect.
  # It arrives in their Case File flagged as served and reads back carrying no
  # Exhibit property, because service gives a Team knowledge and never
  # ammunition. A served Exhibit cannot be answered — there is no rebuttal,
  # because the ratchet leaves nothing to undo.
  #
  # The Exhibit is spent when played; the document is not, and stays in the
  # playing Team's own Case File as what it knows.
  #
  # One document moves one Client **once**, per ADR 0003. The receiving Team may
  # already have found this same document for themselves, and that discovery's
  # shift keys to the same Case File row this one would — so where it is already
  # there, the Exhibit is still spent and still served, and moves nothing.
  class Play
    def self.call(...) = new(...).call

    # `riding` is the Case File rows attached to the Offer that has just
    # committed, re-read from the table inside that commit's transaction.
    def initialize(committed_offer:, riding:)
      @committed_offer = committed_offer
      @riding = riding
    end

    def call
      riding.map { |filed| play(filed) }
    end

    private

    attr_reader :committed_offer, :riding

    def play(filed)
      played = PlayedExhibit.create!(
        side: side, day: day, committed_offer: committed_offer, case_file_document: filed
      )
      # Service is what the shift keys to, so it happens first: the row the
      # other Team reads this document in is the row their Client's movement
      # hangs off, whether service wrote it or they had found it themselves.
      received = serve(filed)
      move_the_other_client(received, filed) if moves_them?(received, filed)
      played
    end

    # The document reaches the other Side in the ordinary Case File, flagged as
    # served rather than found — and returned, because it is the row the shift
    # keys to.
    #
    # A Team that had already discovered it for itself keeps the copy it found.
    # Found is the stronger of the two: it carries the Exhibit property that
    # service withholds, and service is not a way to take one back. The unique
    # index underneath is what makes that the outcome rather than a second row.
    def serve(filed)
      CaseFileDocument.create_or_find_by!(
        side: opponent, case_document: filed.case_document
      ) do |served|
        served.day = day
        served.served_at = Time.current
      end
    end

    # An Exhibit moves a Client only where the Offer it rides touches a Term it
    # bears on, and only where that document has not already moved them. Both
    # are read off rows rather than remembered: the Terms off the committed
    # Offer, because the committed row is the position actually taken, and the
    # movement off the shift ledger.
    def moves_them?(received, filed)
      filed.bears_on?(offered_term_ids) && !ClientShift.already_moved?(received)
    end

    # The Client that moves is the *other* Side's, so the shift hangs off them
    # and keys to their own Case File row. Only the request is ours; the applied
    # figure is the model's, clipped to what is left of the bound.
    def move_the_other_client(received, filed)
      ClientShift.create!(
        side: opponent,
        day: day,
        source_kind: ClientShift::EXHIBIT_PLAYED,
        source_ref: received.id,
        requested_fraction: filed.exhibit_shift_fraction
      )
    end

    def offered_term_ids
      @offered_term_ids ||= committed_offer.offer_terms.pluck(:case_term_id)
    end

    def side = committed_offer.side

    def day = committed_offer.day

    def opponent = @opponent ||= side.opponent
  end
end
