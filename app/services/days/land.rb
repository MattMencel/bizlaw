# frozen_string_literal: true

module Days
  # The one path that fills a Case File — with what a Team walks in with, and
  # then with everything preparation buys it.
  #
  # Preparation pays off on a schedule the Team chose. An Action spent on Day 1
  # with a lead time of 2 produces its documents when Day 3 opens; one with a
  # lead time of zero produces them on the Day it was bought. What a Team starts
  # with waits behind no Action at all and arrives on Day 1, which is the Day it
  # came to know it.
  #
  # It is one seam rather than one per cause. A second writer to
  # `case_file_documents` is the shape `Days::Close` exists to make impossible,
  # and the open hand would be exactly that.
  #
  # Landing writes each yielded document into the finder's Case File. Where the
  # document carries an Exhibit the finder cannot play — one targeting their
  # *own* Client — the shift lands with it, because an unfavorable discovery
  # moves the finder toward realism at the moment it is found.
  #
  # Unless the other Side already served them that same document and moved them
  # with it. One document moves one Client once, per ADR 0003, and the two kinds
  # share a key: the finder's own Case File row, which is the row service wrote
  # if service got there first.
  #
  # It is idempotent, and by unique index rather than by a check-then-write: a
  # Day opened twice, or the same Action bought twice, fills the Case File once
  # and moves the bound once.
  class Land
    # The Day a Team's opening hand arrives on. There is no earlier one.
    FIRST_DAY = 1

    def self.call(...) = new(...).call

    # Dealing is its own verb rather than a branch inside `call`. It happens
    # once, when Day 1 opens, and `call` is reached again by every lead-zero
    # spend on that Day — which would re-attempt an insert per (Side, document)
    # pair already filed, inside the transaction charging the student.
    #
    # Still one writer to `case_file_documents`: the same class, and the Day's
    # open is its only caller.
    def self.deal_the_open_hand(...) = new(...).deal_the_open_hand

    def initialize(day)
      @day = day
    end

    # Returns the Case File rows this Day's landings account for, whether they
    # were written now or on an earlier pass.
    def call
      ActiveRecord::Base.transaction do
        # Reloaded because a spend calls this immediately after appending its own
        # row, and a Day handed in with the association already loaded would
        # otherwise land everything but the Action that just bought it.
        day.landing_docket_entries.reload.flat_map { |entry| land(entry) }
      end
    end

    # What each Team holds before it has done anything: the documents the Case
    # authors into a hand rather than behind a door. They arrive on Day 1
    # because there is no earlier Day for them to have arrived on, and on Day 1
    # they are the whole of what a Case File holds.
    #
    # Idempotent by the same unique index as everything else here, so a Day 1
    # re-opened deals the hand once — and it asks which rows are already there
    # rather than re-attempting every insert, because a failed insert costs a
    # savepoint rollback and a fallback select apiece.
    #
    # An unfavorable Exhibit cannot be authored into a hand, so nothing here can
    # move a Client before the first Day is played.
    def deal_the_open_hand
      return [] unless day.ordinal == FIRST_DAY

      ActiveRecord::Base.transaction do
        day.simulation.sides.flat_map { |side| deal_to(side) }
      end
    end

    private

    attr_reader :day

    def deal_to(side)
      wanted = open_hand.select { |document| document.held_at_the_open_by?(side.role) }
      already = side.case_file_documents.where(case_document: wanted).pluck(:case_document_id)

      wanted.reject { |document| already.include?(document.id) }
        .map { |document| file(side, document) }
    end

    def open_hand
      @open_hand ||= day.simulation.case_version.documents.in_hand_at_the_open.to_a
    end

    # An Offer commit is a spend with no authored Action behind it, so there is
    # nothing for it to yield. The Exhibits that ride one land through their own
    # seam, `Exhibits::Play`, in the commit's own transaction.
    def land(entry)
      return [] if entry.case_action.nil?

      entry.case_action.documents.map do |document|
        filed = file(entry.side, document)
        discover_unfavorably(filed) if filed.unfavorable?
        filed
      end
    end

    # Found outranks served. A document this Team was shown by the other Side and
    # has now found for itself is a document it found: service withholds the
    # Exhibit property and is not a way to take one back. The Day stays the Day
    # the document first arrived, because that is when this Team came to know it.
    def file(side, document)
      filed = CaseFileDocument.create_or_find_by!(side: side, case_document: document) do |row|
        row.day = day
      end
      filed.update!(served_at: nil) if filed.served?
      filed
    end

    # The shift is keyed to the Case File row rather than to the Docket entry:
    # two Actions cannot yield the same document to the same Side twice, so this
    # is the one row the discovery exists as, and its id is stable across a
    # re-open.
    def discover_unfavorably(filed)
      # The ledger is checked rather than left to the index. `create_or_find_by!`
      # retries its `find_by!` on the attributes it was handed, would not match
      # the `exhibit_played` row already there, and would raise `RecordNotFound`
      # out of a Day open. The rule is ADR 0003's, so it reads as the rule.
      return if ClientShift.already_moved?(filed)

      ClientShift.create_or_find_by!(
        side: filed.side,
        source_kind: ClientShift::UNFAVORABLE_DISCOVERY,
        source_ref: filed.id
      ) do |shift|
        shift.day = day
        # The applied figure is the model's; only the request is ours.
        shift.requested_fraction = filed.exhibit_shift_fraction
      end
    end
  end
end
