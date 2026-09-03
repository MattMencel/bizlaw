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
      "calendar" => (0..9).map { |index| Date.new(2026, 3, 2) + index },
      "budget" => {
        "per_day" => 10,
        "exchange_pool" => 2,
        "closing_knee" => 0.60,
        "closing_preparation" => 2,
        "closing_exchange" => 3
      },
      "actions" => {
        "consult_client" => {"cost" => 1, "lead_time_days" => 0, "half" => "preparation"},
        "depose_witness" => {"cost" => 3, "lead_time_days" => 2, "half" => "preparation"}
      }
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

  it "loads the authored Action Budget the Day's quota is sized from" do
    version = described_class.call(Rails.root.join("db/cases/reference.yml"))

    expect(version.budget_per_day).to eq(10)
    expect(version.exchange_pool).to eq(2)
    expect(version.closing_knee).to eq(0.60)
    expect(version.closing_preparation).to eq(2)
    expect(version.closing_exchange).to eq(3)
  end

  it "loads the reference Case's Action menu, each Action with its cost, lead time and half" do
    version = described_class.call(Rails.root.join("db/cases/reference.yml"))

    expect(version.actions.map { |action|
      [action.kind, action.cost, action.lead_time_days, action.half]
    }).to contain_exactly(
      [CaseAction::CONSULT_CLIENT, 1, 0, DayBudget::PREPARATION],
      [CaseAction::REQUEST_DOCUMENTS, 2, 1, DayBudget::PREPARATION],
      [CaseAction::RESEARCH_PRECEDENT, 2, 1, DayBudget::PREPARATION],
      [CaseAction::MANAGE_PRESS, 2, 1, DayBudget::PREPARATION],
      [CaseAction::DEPOSE_WITNESS, 3, 2, DayBudget::PREPARATION],
      [CaseAction::RETAIN_EXPERT, 5, 2, DayBudget::PREPARATION]
    )
  end

  it "replaces the Action menu of a draft, as it does the calendar" do
    described_class.call(authored(published: false))

    version = described_class.call(
      authored(published: false,
        actions: {"manage_press" => {"cost" => 4, "lead_time_days" => 1, "half" => "preparation"}})
    )

    expect(version.actions.map(&:kind)).to eq([CaseAction::MANAGE_PRESS])
    expect(CaseAction.count).to eq(1)
  end

  it "refuses a Case that authors no Action menu" do
    expect { described_class.call(authored(actions: nil)) }
      .to raise_error(described_class::InvalidCase, /actions/)
  end

  it "refuses a Case authoring an Action kind the engine does not know" do
    expect {
      described_class.call(authored(actions: {
        "subpoena_the_mayor" => {"cost" => 2, "lead_time_days" => 1, "half" => "preparation"}
      }))
    }.to raise_error(described_class::InvalidCase, /subpoena_the_mayor/)
  end

  it "refuses an Action authored without a cost, a lead time or a half" do
    expect { described_class.call(authored(actions: {"consult_client" => {"cost" => 1}})) }
      .to raise_error(described_class::InvalidCase, /consult_client/)
  end

  it "refuses an Action that costs nothing, because an Action is a spend" do
    expect {
      described_class.call(authored(actions: {
        "consult_client" => {"cost" => 0, "lead_time_days" => 0, "half" => "preparation"}
      }))
    }.to raise_error(described_class::InvalidCase, /consult_client/)
  end

  it "refuses an Action priced in fractions of a point" do
    expect {
      described_class.call(authored(actions: {
        "consult_client" => {"cost" => 2.7, "lead_time_days" => 0, "half" => "preparation"}
      }))
    }.to raise_error(described_class::InvalidCase, /not a whole number/)
  end

  it "refuses an Action whose lead time is not a whole number of Days" do
    expect {
      described_class.call(authored(actions: {
        "consult_client" => {"cost" => 1, "lead_time_days" => 1.5, "half" => "preparation"}
      }))
    }.to raise_error(described_class::InvalidCase, /not a whole number/)
  end

  it "refuses an Action whose lead time reaches backwards" do
    expect {
      described_class.call(authored(actions: {
        "consult_client" => {"cost" => 1, "lead_time_days" => -1, "half" => "preparation"}
      }))
    }.to raise_error(described_class::InvalidCase, /consult_client/)
  end

  it "refuses an Action drawing on a half the Budget does not have" do
    expect {
      described_class.call(authored(actions: {
        "consult_client" => {"cost" => 1, "lead_time_days" => 0, "half" => "goodwill"}
      }))
    }.to raise_error(described_class::InvalidCase, /consult_client/)
  end

  it "refuses a Case whose exchange half cannot play an Offer with an Exhibit behind it" do
    under = {"per_day" => 10, "exchange_pool" => 1, "closing_knee" => 0.60,
             "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: under)) }
      .to raise_error(described_class::InvalidCase, /exchange/)
  end

  it "refuses a Case whose closing exchange half falls under two points" do
    under = {"per_day" => 10, "exchange_pool" => 2, "closing_knee" => 0.60,
             "closing_preparation" => 2, "closing_exchange" => 1}

    expect { described_class.call(authored(budget: under)) }
      .to raise_error(described_class::InvalidCase, /exchange/)
  end

  it "refuses a Case that authors no Action Budget" do
    expect { described_class.call(authored(budget: nil)) }
      .to raise_error(described_class::InvalidCase, /budget/)
  end

  it "refuses a Case whose Budget is missing a value" do
    expect { described_class.call(authored(budget: {"per_day" => 10})) }
      .to raise_error(described_class::InvalidCase, /budget/)
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
