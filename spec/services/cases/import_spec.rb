# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

RSpec.describe Cases::Import do
  around do |example|
    Dir.mktmpdir("case-import") do |dir|
      @dir = dir
      example.run
    end
  end

  def authored(**overrides)
    data = {
      "identifier" => "bizlaw/reference",
      "name" => "The Reference Case",
      "licence" => "Apache-2.0",
      "version" => "1.0.0",
      "published" => true,
      "calendar" => (0..9).map { |index| Date.new(2026, 3, 2) + index }
    }.merge(overrides.transform_keys(&:to_s))

    File.join(@dir, "case.yml").tap { |path| File.write(path, data.to_yaml) }
  end

  it "loads a Case Version carrying a Day count and an ordered calendar" do
    version = described_class.call(authored)

    expect(version.case.identifier).to eq("bizlaw/reference")
    expect(version.case.licence).to eq("Apache-2.0")
    expect(version.day_count).to eq(10)
    expect(version.calendar_days.map(&:ordinal)).to eq((1..10).to_a)
    expect(version.calendar_days.first.in_fiction_date).to eq(Date.new(2026, 3, 2))
    expect(version.calendar_days.last.in_fiction_date).to eq(Date.new(2026, 3, 11))
  end

  it "loads the repository's reference Case" do
    version = described_class.call(Rails.root.join("db/cases/reference.yml"))

    expect(version).to be_published
    expect(version.day_count).to eq(10)
  end

  it "loads an unpublished version as a draft" do
    expect(described_class.call(authored(published: false))).to be_draft
  end

  it "refuses to re-import a published version, which never changes again" do
    described_class.call(authored)

    expect { described_class.call(authored) }
      .to raise_error(described_class::PublishedVersionExists)
  end

  it "replaces the calendar of a draft, which is the professor's working copy" do
    described_class.call(authored(published: false))

    version = described_class.call(
      authored(published: false, calendar: [Date.new(2026, 5, 4), Date.new(2026, 5, 5)])
    )

    expect(version.day_count).to eq(2)
    expect(CaseVersion.count).to eq(1)
  end

  it "refuses a Case that authors no calendar" do
    expect { described_class.call(authored(calendar: [])) }
      .to raise_error(described_class::InvalidCase, /calendar/)
  end

  it "refuses a Case whose calendar is out of order" do
    out_of_order = [Date.new(2026, 3, 4), Date.new(2026, 3, 2)]

    expect { described_class.call(authored(calendar: out_of_order)) }
      .to raise_error(described_class::InvalidCase, /order/)
  end

  it "refuses a path that cannot be read" do
    expect { described_class.call(File.join(@dir, "absent.yml")) }
      .to raise_error(described_class::InvalidCase, /not readable as a Case/)
  end

  it "refuses a file that is not YAML" do
    path = File.join(@dir, "broken.yml").tap { |file| File.write(file, "\tnot: yaml") }

    expect { described_class.call(path) }
      .to raise_error(described_class::InvalidCase, /not readable as a Case/)
  end

  it "refuses a Case missing its licence" do
    expect { described_class.call(authored(licence: nil)) }
      .to raise_error(described_class::InvalidCase, /licence/)
  end
end
