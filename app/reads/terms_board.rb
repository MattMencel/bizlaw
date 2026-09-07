# frozen_string_literal: true

# Where the shape of the deal is visible: each Term as a track carrying the
# Team's own position, the other Side's last committed Offer, and the Team's own
# Client's stated aspiration.
#
# **It never shows Par.** Par is what the grade is measured against, and no
# rubric-derived number reaches a student before Release. The aspiration is the
# in-fiction stand-in, and it gives nothing away because it does not move: a
# Client still wants what they wanted, so their stated demands never reveal that
# they have softened.
#
# Three slots and three ways to be silent, which the read keeps distinct. A
# Term nobody has put on the table is nil, never zero — an offer of nothing is a
# position somebody took, and this did not happen. A Term on the table without a
# figure is a `Position` carrying no amount, because a Team offering an apology
# is offering an apology. And a Term the Client is indifferent about has no
# aspiration authored at all.
class TermsBoard
  # One Term as somebody has it. Present is the whole of what this says; the
  # amount is absent on the Terms that carry no figure, which is most of them.
  Position = Data.define(:amount_cents) do
    def money? = !amount_cents.nil?
  end

  # One track. `ours_staged` says the Team's own slot is a live draft rather
  # than a position already taken, which is the difference between a thing being
  # deliberated and a thing that has been done. Committing does not delete the
  # draft it was copied from, so a draft with a committed Offer behind it on the
  # same Day is a position taken: the Team cannot commit a second one that Day,
  # and the first is already on the other Side's table.
  Track = Data.define(:term, :ours, :ours_staged, :theirs, :aspiration) do
    def on_the_table? = !ours.nil? || !theirs.nil?
  end

  def self.for(...) = new(...)

  def initialize(side, day:)
    @side = side
    @day = day
  end

  # In the order the Case authors its vocabulary, so the board reads the same
  # for both Teams and across Days.
  def tracks
    @tracks ||= side.case_version.terms.order(:id).map do |term|
      Track.new(
        term: term.key,
        ours: ours[term.id],
        ours_staged: still_a_draft?,
        theirs: theirs[term.id],
        aspiration: aspirations[term.id]
      )
    end
  end

  private

  attr_reader :side, :day

  # The Team's own position: the draft on today's table if there is one, and
  # otherwise the last Offer it actually committed. A Team with no draft today
  # has not withdrawn what it already put in front of the other Side.
  def ours
    @ours ||= positions(staged || last_committed(side))
  end

  # `defined?` rather than `||=`, which memoizes nothing when there is no draft
  # and asks the database again for every track on the board.
  def staged
    return @staged if defined?(@staged)

    @staged = side.staged_offer_on(day)
  end

  def still_a_draft? = !staged.nil? && side.committed_offer_on(day).nil?

  # The other Side's last committed Offer, read **whole**. Never a per-Term
  # latest assembled across several: a composite of the furthest each Term ever
  # reached is a position nobody put on the table.
  #
  # It reaches `committed_offers`, which per ADR 0002 is a separate table from
  # the drafts precisely so that a cross-Side read cannot find a live position.
  def theirs
    @theirs ||= positions(last_committed(side.opponent))
  end

  # Last **as of this Day**, which is the whole board's tense: the draft slot
  # above is already scoped to the Day, and a board mixing the two would be a
  # position nobody held at any one moment.
  #
  # Live play cannot reach a later Offer — a commit needs an open Day carrying a
  # Budget row, and `Days::Close` opens the next Day only as it closes this one,
  # so the newest committed Offer is always on the Day being played or before
  # it. The scope is here for the readers that are not play: an Instructor
  # reading a running Simulation, and the Debrief reading a finished one.
  def last_committed(of)
    of.committed_offers.joins(:day).where(days: {ordinal: ..day.ordinal}).last
  end

  def positions(offer)
    return {} if offer.nil?

    offer.offer_terms.to_h { |row| [row.case_term_id, Position.new(amount_cents: row.amount_cents)] }
  end

  # Sparse by authoring: a Term with none is one this Client is indifferent
  # about, and its track carries the two live positions and no marker.
  def aspirations
    @aspirations ||= side.client.aspirations.to_h do |aspiration|
      [aspiration.case_term_id, Position.new(amount_cents: aspiration.amount_cents)]
    end
  end
end
