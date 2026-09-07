# frozen_string_literal: true

# The accumulating results of a Team's Actions, and what it walked in with.
# Answers *what do we know*, as against the Docket's *what have we done*.
#
# Everything in it is a document. Some documents also carry an Exhibit — the
# Case File is a folder that happens to hold a few playable things, not a hand —
# and the documents the other Side has served arrive flagged as served, carrying
# no Exhibit property at all, because service gives a Team knowledge and never
# ammunition.
#
# A fold over `case_file_documents` and nothing else. Whether an Exhibit is
# spent, whether it is playable and whether service or discovery got there first
# are all the row's own reads; this puts them in one order and answers the one
# question a surface asks that a row cannot: whether this Team has ever held an
# Exhibit at all.
class CaseFile
  FOUND = :found
  SERVED = :served

  # One document, as a Team reads it. `playable` is false on a document carrying
  # no Exhibit, on one pointing at this Team's own Client, on one already spent,
  # and on anything served — four different reasons, all of them *not a control
  # to reach for*, which is the only distinction a folder has to draw.
  # `at_the_open` is Provenance rather than a date: **this** Team walked in
  # holding it, as against having bought it. The Day cannot say so — an Action
  # with no lead time bought on Day 1 lands on Day 1 too — and neither can the
  # document alone, because a hand belongs to a Side: a document the other Side
  # walked in with can reach this one by service, and it is not something this
  # Team started with.
  #
  # `identifier` is the authored name, which is what lets a briefing match a
  # document against the Actions that produced it.
  Entry = Data.define(
    :identifier, :title, :body, :day, :arrival, :playable, :spent, :at_the_open
  ) do
    def served? = arrival == SERVED

    def found? = arrival == FOUND

    def at_the_open? = at_the_open
  end

  def self.for(...) = new(...)

  def initialize(side)
    @side = side
  end

  # In the order the documents arrived, and within a Day in the order they were
  # filed. What a Team walked in with therefore reads first, because it arrived
  # on Day 1 before anything was spent.
  def entries
    @entries ||= rows.map do |filed|
      Entry.new(
        identifier: filed.case_document.identifier,
        title: filed.title,
        body: filed.body,
        day: filed.day,
        arrival: filed.served? ? SERVED : FOUND,
        playable: filed.playable?,
        spent: filed.played?,
        # Asked of this Side's own hand, the way `Days::Land` deals it.
        at_the_open: filed.case_document.held_at_the_open_by?(side.role)
      )
    end
  end

  def empty? = entries.empty?

  # The empty state is the tutorial: a Case File holding nothing says what a
  # Case File would hold. It is nil once there is something to read, so a
  # surface cannot show the lesson over the thing it was teaching.
  def empty_state = empty? ? I18n.t("reads.case_file.empty") : nil

  # Whether the Exhibit affordances are real yet. This is the one thing in the
  # whole surface that gates, and it gates on Team state rather than on a Day
  # count or a per-student flag, because there is no per-student state to keep.
  #
  # It reads *has this Team ever held a playable Exhibit*, not *does it hold one
  # now*: a Team that has spent its only Exhibit has still learned what the
  # control does, and taking the affordance away again would teach the opposite.
  # A served document never counts — it carries no Exhibit property for its
  # recipient — and neither does an unfavorable one, which is not playable at
  # all and whose affordance would be inert.
  def exhibits_available? = entries.any? { |entry| entry.playable || entry.spent }

  private

  attr_reader :side

  # `played_exhibit` is what `playable?` and `played?` read, once per row.
  # `document_terms` is read only by `CaseFileDocument#bears_on?`, which
  # `pluck`s and would bypass a preload anyway.
  def rows
    side.case_file_documents.includes(:day, :case_document, :played_exhibit)
      .sort_by { |filed| [filed.day.ordinal, filed.id] }
  end
end
