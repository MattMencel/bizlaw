# frozen_string_literal: true

require "rails_helper"

RSpec.describe Retention do
  # The purge job, the Section end date it is measured from and the tombstone
  # rendering are not built here. What is built is the declaration, so that a
  # later table added without one breaks rather than quietly retaining student
  # writing forever.
  {
    Case => :authored,
    CaseVersion => :authored,
    CaseCalendarDay => :authored,
    CaseAction => :authored,
    CaseClient => :authored,
    CaseTerm => :authored,
    CaseDocument => :authored,
    CaseDocumentTerm => :authored,
    Organization => :skeleton,
    User => :skeleton,
    Section => :skeleton,
    Simulation => :skeleton,
    Side => :skeleton,
    Day => :skeleton,
    DayBudget => :skeleton,
    DocketEntry => :skeleton,
    CaseFileDocument => :skeleton,
    ClientShift => :skeleton
  }.each do |model, tier|
    it "declares #{model.name} as #{tier}" do
      expect(model.retention_tier).to eq(tier)
    end
  end

  it "raises rather than defaulting when a model declares no tier" do
    undeclared = Class.new(ApplicationRecord) do
      def self.name = "Undeclared"
    end

    expect { undeclared.retention_tier }.to raise_error(described_class::UndeclaredTier)
  end

  it "refuses a tier the purge does not know" do
    model = Class.new(ApplicationRecord)

    expect { model.retention(:archival) }.to raise_error(ArgumentError)
  end

  it "names the prose columns of a table that holds both" do
    model = Class.new(ApplicationRecord) do
      retention :skeleton, prose: [:note]
    end

    expect(model.prose_columns).to eq(["note"])
  end

  it "names no prose columns where a table holds none" do
    expect(Day.prose_columns).to eq([])
  end
end
