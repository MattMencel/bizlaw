# frozen_string_literal: true

require "rails_helper"

# The purge job, the Section end date it is measured from and the tombstone
# rendering are not built here. What is built is the declaration and the spec
# that enforces it, so that a table added later without one breaks the build
# rather than quietly retaining student writing forever.
#
# The enforcement starts at the schema rather than at a list of models kept in
# this file: a maintained list drifts silently, which is the failure the
# declaration exists to prevent.
RSpec.describe Retention do
  it "declares a tier for every table the engine carries" do
    expect(tables_without_a_tier).to be_empty
  end

  # The proof that the enumeration bites: a table the spec adds itself, with no
  # model and so no declaration, is what a later prose-bearing table added
  # without a tier looks like to this spec.
  it "fails on a table added without a declaration" do
    connection.create_table(:undeclared_deliberations) { |t| t.text :body }

    expect(tables_without_a_tier).to eq(["undeclared_deliberations"])
  ensure
    connection.drop_table(:undeclared_deliberations, if_exists: true)
  end

  # A declaration naming a column the table does not have empties nothing, and
  # the purge would pass over prose that is still sitting there.
  it "names prose columns the table actually has" do
    missing = declared_models.filter_map do |table, model|
      absent = model.prose_columns - model.column_names
      "#{model.name} names #{absent.join(", ")} on #{table}" if absent.any?
    end

    expect(missing).to be_empty
  end

  # Both clocks are hard deletes. A `deleted_at` row still holding the prose is
  # not a purge, and a soft-deleted skeleton keeps every student name forever.
  it "carries no soft-deletion column on any table" do
    soft = engine_tables.select do |table|
      connection.columns(table).map(&:name).intersect?(%w[deleted_at discarded_at archived_at])
    end

    expect(soft).to be_empty
  end

  # The professor's work, never a student record, never purged.
  it "declares the authored Case and its pinned Versions as authored" do
    expect(Case.retention_tier).to eq(:authored)
    expect(CaseVersion.retention_tier).to eq(:authored)
  end

  # The graded shape of a run, with Attribution, outliving the prose inside it.
  it "declares the Day's economy as the graded skeleton" do
    expect(Day.retention_tier).to eq(:skeleton)
    expect(DocketEntry.retention_tier).to eq(:skeleton)
    expect(CommittedOffer.retention_tier).to eq(:skeleton)
    expect(ClientShift.retention_tier).to eq(:skeleton)
    expect(CaseFileDocument.retention_tier).to eq(:skeleton)
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

  it "names no prose columns where a table holds none" do
    expect(Day.prose_columns).to eq([])
  end

  # The Offer's shape is the graded skeleton and outlives the run by a year. The
  # note is free text the Instructor reads, and it is Student Prose on the
  # 30-day clock — so the row survives the earlier purge as a tombstone with the
  # writing emptied out of it where it sat.
  it "names the Offer note as the prose on an otherwise skeleton row" do
    expect(StagedOffer.prose_columns).to eq(["note"])
    expect(CommittedOffer.prose_columns).to eq(["note"])
  end

  def connection = ActiveRecord::Base.connection

  # Rails' own bookkeeping is not a student record and holds no prose.
  def engine_tables = connection.tables - %w[ar_internal_metadata schema_migrations]

  # Eagerly, because the declaration is only reachable through the model and a
  # lazily loaded one is a table this spec would not see.
  def models_by_table
    Rails.application.eager_load!
    ApplicationRecord.descendants.reject(&:abstract_class?).index_by(&:table_name)
  end

  def declared_models
    models_by_table.slice(*engine_tables).select { |_table, model| tier_of(model) }
  end

  def tables_without_a_tier
    by_table = models_by_table
    engine_tables.reject { |table| tier_of(by_table[table]) }
  end

  def tier_of(model)
    model&.retention_tier
  rescue described_class::UndeclaredTier
    nil
  end
end
