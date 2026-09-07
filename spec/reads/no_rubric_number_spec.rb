# frozen_string_literal: true

require "rails_helper"

# **No rubric-derived number is ever visible to a student before the Instructor
# releases it.** The Rubric itself is published in full on day one — that is
# copy, and the Morning Briefing carries it — but every *figure* the grade is
# computed from or against is the Instructor's until Release.
#
# Two other private numbers travel with them here, on one list rather than two.
# A Client's live reservation point would hand that number to any Team willing
# to probe for it, and a Client's per-Term valuation is what an Offer is scored
# by. Neither is rubric-derived; both are refused from the same surfaces for the
# same reason, and one list that catches all three cannot drift from a second
# list that was supposed to agree with it.
#
# The absence is asserted against the objects rather than against a screen,
# because no interface can accidentally show a figure no object computes.
RSpec.describe "the figures no student-facing read exposes" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }

  # A vocabulary rather than a list of methods: what the design refuses is the
  # *figure*, so a reader that arrives later under any of these names is caught
  # whatever object it hangs off.
  #
  # Matched as whole underscore-delimited words, because `\bpar\b` does not see
  # the `par` in `par_for_this_side` — `_` is a word character, so there is no
  # boundary there — and a sweep that misses the most likely spelling of the
  # thing it forbids is worse than none.
  let(:forbidden_words) do
    %w[par score grade settlement_quality valuation reservation bound]
  end

  let(:forbidden) { /(\A|_)(#{Regexp.union(forbidden_words).source})s?(\z|_)/ }

  let(:reads) do
    [Docket, CaseFile, ActionBoard, TermsBoard, MorningBriefing, ExecutedInstrument]
  end

  it "defines no such reader on any read object" do
    offenders = reads.flat_map { |read|
      (read.instance_methods(false) + read.singleton_methods(false))
        .grep(forbidden)
        .map { |method| "#{read}##{method}" }
    }

    expect(offenders).to be_empty
  end

  # The sweep above reads the objects the app has loaded. This one reads the
  # source, so a private method — which a caller could still be given later —
  # is caught as well.
  it "defines no such reader anywhere under app/reads" do
    offenders = Rails.root.glob("app/reads/**/*.rb").flat_map { |file|
      file.readlines.filter_map { |line|
        name = line[/^\s*def (?:self\.)?([a-z_]\w*[?!]?)/, 1]
        "#{file.relative_path_from(Rails.root)}##{name}" if name&.match?(forbidden)
      }
    }

    expect(offenders).to be_empty
  end

  # Every value a read hands back is one of these too. A Data member named for a
  # forbidden figure is a number reaching a student through a field rather than
  # through a method, which the sweep above would not see.
  it "names no such member on anything a read hands back" do
    carried = [
      Docket::Entry, CaseFile::Entry, ActionBoard::Entry,
      TermsBoard::Track, TermsBoard::Position,
      MorningBriefing::CalendarDay, MorningBriefing::Rubric,
      ExecutedInstrument::Term, ExecutedInstrument::Countersignature, ExecutedInstrument::Beat
    ]

    expect(carried.flat_map(&:members).grep(forbidden)).to be_empty
  end

  # The Terms Board is the surface Par would most plausibly be added to, so its
  # shape is pinned rather than only swept. Three slots and no fourth: the
  # Client's aspiration is the in-fiction stand-in precisely because Par cannot
  # be one of them.
  it "gives the Terms Board three slots per Term and no room for a fourth" do
    expect(TermsBoard::Track.members).to eq(%i[term ours ours_staged theirs aspiration])
  end

  # The published Rubric is copy, and copy is what a student is owed on day one.
  # What it must not carry is a figure about *this* Team.
  it "publishes the Rubric as copy and computes nothing from it" do
    rubric = MorningBriefing.for(side, day: day).rubric

    expect(rubric.dimensions).to all(be_a(String))
    expect(rubric.bonus).to be_a(String)
    expect(MorningBriefing::Rubric.members).to eq(%i[dimensions bonus])
  end

  # The settlement beat is where a figure about how the deal landed would most
  # plausibly be added — against the Client's aspiration, or against their
  # reservation point. Both are refused: Settlement Quality is rubric-derived
  # and pre-Release, and a Section's concurrent Simulations would carry a
  # Client's number from a settled Team to one still playing the same Case.
  it "gives the Client's settlement beat words and a face and nothing computed" do
    expect(ExecutedInstrument::Beat.members)
      .to eq(%i[client_role acceptance_role line expression])
  end

  # A Team's own Client's bound is authored money and the one number every shift
  # is a fraction of. It is the Instructor's, and the only read a Team ever gets
  # on where their Client stands is a Reaction Band bought with an Action.
  it "reaches no Client's bound or private position through any read" do
    surfaces = [
      Docket.for(side), CaseFile.for(side), ActionBoard.for(side, day: day),
      TermsBoard.for(side, day: day), MorningBriefing.for(side, day: day),
      ExecutedInstrument.for(side)
    ]

    expect(surfaces.flat_map { |read| read.public_methods(false) }.grep(forbidden)).to be_empty
  end
end
