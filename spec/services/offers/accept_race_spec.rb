# frozen_string_literal: true

require "rails_helper"

# **A run settles once.** Two Teams can hold each other's Offers on one open Day
# and both press accept, and only one of those can be the Acceptance that ended
# the Simulation.
#
# What refuses the second is not the `settled?` gate in `Offers::Accept` — that
# gate reads outside the transaction, so a caller can genuinely read the run as
# live while the winner's row is written and uncommitted. It is the
# `offer_acceptances_need_an_unclosed_day` trigger: exactly one Day of a run is
# open at a time, because `Days::Close` opens the next only as it closes this
# one, so the loser always lands on the Day the winner has just closed. The gate
# is what turns that fault into `Simulation::AlreadySettled`.
#
# The interleaving is forced rather than hoped for. Left to a barrier, SQLite's
# single writer serializes the two calls and the loser's `settled?` read simply
# sees the winner's row — a green spec that would stay green with the rescue
# deleted. So the winner is held inside its own transaction, after its insert,
# while the loser takes the read that makes it a loser. That is instrumenting
# the service, and it is the only version of this spec that proves anything.
#
# Real threads need real connections, so this group runs outside the transaction
# every other spec runs inside and empties the tables itself afterwards.
RSpec.describe "two Teams settling one run at the same moment" do
  self.use_transactional_tests = false

  after do
    ActiveRecord::Base.connection.disable_referential_integrity do
      (ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata])
        .each { |table| ActiveRecord::Base.connection.delete("DELETE FROM #{table}") }
    end
  end

  let(:simulation) { a_simulation }
  let(:organization) { simulation.section.organization }
  let(:day) { simulation.days.first }
  let(:sides) { [simulation.plaintiff_side, simulation.defendant_side] }

  def a_team(index)
    %w[took seconded].map.with_index do |role, position|
      a_user(
        organization: organization,
        name: "#{role.capitalize} #{index}",
        email: "#{role}#{index}#{position}@example.edu"
      )
    end
  end

  # An Offer from each Side on the same Day. The second commit is also the
  # second Day commit, so Day 1 closes and Day 2 opens with both on the table.
  def offers_on_both_tables(teams)
    sides.map.with_index do |side, index|
      taker, seconder = teams[index]
      Days::Command.apply(
        act: :spend, side: side, day: day, by: seconder, kind: CaseAction::CONSULT_CLIENT
      )
      Offers::Stage.call(
        side: side, day: day, by: taker, terms: {"money" => (40 + index) * 1_000_00}
      )
      Days::Command.apply(
        act: :commit_offer, side: side, day: day, by: taker, seconded_by: seconder
      )
    end
  end

  def in_its_own_connection
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection { yield }
    rescue => e
      e
    end
  end

  it "writes one Acceptance and tells the other Team the run had already ended" do
    teams = [a_team(0), a_team(1)]
    offers = offers_on_both_tables(teams)
    on = simulation.days.second

    # The winner is held here, inside its transaction and after its insert, so
    # the loser's `settled?` read happens against a run that is about to be
    # settled and does not look it yet.
    inserted = Queue.new
    close = Days::Close.method(:call)
    allow(Days::Close).to receive(:call) do |closing|
      inserted << :now
      sleep 0.4
      close.call(closing)
    end

    winner = in_its_own_connection do
      Offers::Accept.call(
        offer: offers[0], side: sides[1], day: on,
        by: teams[1][0], seconded_by: teams[1][1]
      )
    end
    inserted.pop
    loser = in_its_own_connection do
      Offers::Accept.call(
        offer: offers[1], side: sides[0], day: on,
        by: teams[0][0], seconded_by: teams[0][1]
      )
    end

    expect(winner.value).to be_a(OfferAcceptance)
    expect(loser.value).to be_a(Simulation::AlreadySettled)
    expect(OfferAcceptance.count).to eq(1)
    expect(simulation.reload.settlement).to eq(winner.value)
  end
end
