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
  # Terms are given as a Hash over the Case's authored vocabulary, mapping each
  # Term's key to money's amount in cents and every other Term to nil:
  #
  #   Offers::Stage.call(side:, day:, by:, terms: {"money" => 45_000_00, "apology" => nil})
  #
  # A key the Case does not author is a caller with a vocabulary the engine
  # never offered, not a refusal a student should see, so it raises.
  class Stage
    def self.call(...) = new(...).call

    def initialize(side:, day:, by:, terms:, note: nil)
      @side = side
      @day = day
      @by = by
      @terms = terms
      @note = note
    end

    def call
      raise DayClosed, "Day #{day.ordinal} has already closed" if day.closed?

      vocabulary = terms_authored_for(terms.keys)

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
        offer.reload
      end
    end

    private

    attr_reader :side, :day, :by, :terms, :note

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
