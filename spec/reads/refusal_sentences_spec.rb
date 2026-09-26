# frozen_string_literal: true

require "rails_helper"

# **Every refusal the seams can return has a sentence.** `Days::Command` and
# `Offers::*` name the rule an act was turned down by with a symbol, and a page
# prints `reads.refusals.<symbol>`. The test environment raises on a missing
# key, but only for a refusal some spec happens to reach; this reads the seams
# themselves, so a refusal nobody has provoked yet is still owed its words.
#
# `Offers::Stage` refuses by raising, and `Demo::OffersController` is where
# those raises become symbols, so the demo's controllers are read too.
#
# A refusal is a Symbol literal in one of three places: an argument to
# `refusal(...)` or `refuse(...)`, a `return` inside a method whose name says it
# refuses, or the last expression of such a method.
RSpec.describe "the sentence for every refusal" do
  let(:seams) do
    [
      Rails.root.join("app/services/days/command.rb"),
      Rails.root.join("app/services/days/commit.rb"),
      *Rails.root.glob("app/services/offers/*.rb"),
      *Rails.root.glob("app/controllers/demo/*.rb")
    ]
  end

  # Refusals that may go without a sentence. It only shrinks: an entry the seams
  # no longer return fails below.
  let(:allowed) { [] }

  def refusals_in(source) = RefusalSymbols.new(Ripper.sexp(source)).symbols

  def refusals = seams.flat_map { |seam| refusals_in(seam.read) }.uniq

  it "finds the refusals the seams are known to return" do
    expect(refusals).to include(
      :the_budget_cannot_cover_it, :the_offer_has_not_been_seconded,
      :the_acceptance_has_not_been_seconded, :an_offer_has_already_been_committed_today
    )
  end

  it "has a sentence for each" do
    unworded = refusals.reject { |symbol| I18n.exists?("reads.refusals.#{symbol}", :en) } - allowed

    expect(unworded).to be_empty
  end

  it "allows nothing the seams no longer return" do
    expect(allowed - refusals).to be_empty
  end

  describe "reading a seam" do
    it "finds a refusal passed to `refusal`, returned, or left last" do
      source = <<~RUBY
        def quote = refusal(:the_first, landing_day: 1)
        def gate_refusal
          return nil unless act == :commit_offer
          return :the_second if missing?
          :the_third
        end
        def create = refuse(seated, :the_fourth)
      RUBY

      expect(refusals_in(source)).to contain_exactly(:the_first, :the_second, :the_third, :the_fourth)
    end
  end
end
