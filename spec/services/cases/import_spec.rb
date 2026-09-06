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
        "exhibit_price" => 1,
        "closing_knee" => 0.60,
        "closing_preparation" => 2,
        "closing_exchange" => 3
      },
      "actions" => {
        "consult_client" => {"cost" => 1, "lead_time_days" => 0, "half" => "preparation"},
        "depose_witness" => {"cost" => 3, "lead_time_days" => 2, "half" => "preparation"}
      },
      "clients" => {
        "plaintiff" => {"bound" => 40_000, "opening_statement" => "I want my name back."},
        "defendant" => {"bound" => 60_000, "opening_statement" => "I want this closed quietly."}
      },
      "terms" => %w[money reinstatement],
      "documents" => {
        "deposition_of_the_supervisor" => {
          "action" => "depose_witness",
          "title" => "Deposition of the plant supervisor",
          "body" => "Two dated memoranda and a signed acknowledgement.",
          "exhibit" => {
            "target" => "plaintiff",
            "shift" => 0.25,
            "bears_on" => %w[money reinstatement]
          }
        }
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
    expect(version.exhibit_price).to eq(1)
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
        actions: {"manage_press" => {"cost" => 4, "lead_time_days" => 1, "half" => "preparation"}},
        documents: {
          "the_local_paper" => {
            "action" => "manage_press",
            "title" => "Coverage in the local paper",
            "body" => "Six column inches, and a photograph of the gates."
          }
        })
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
    under = {"per_day" => 10, "exchange_pool" => 1, "exhibit_price" => 1,
             "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: under)) }
      .to raise_error(described_class::InvalidCase, /exchange/)
  end

  # The Exhibit's price and the pool are one decision rather than two. At a pool
  # of two an Exhibit priced at two means nothing can ever be played, and
  # separation across the joint grid falls from 84 to 10.
  it "refuses an Exhibit priced past the Offer it has to ride" do
    crowded = {"per_day" => 10, "exchange_pool" => 2, "exhibit_price" => 2,
               "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: crowded)) }
      .to raise_error(described_class::InvalidCase, /leaves no Offer for it to ride/)
  end

  it "refuses an Exhibit that costs nothing" do
    free = {"per_day" => 10, "exchange_pool" => 2, "exhibit_price" => 0,
            "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: free)) }
      .to raise_error(described_class::InvalidCase, /Exhibit costing 0/)
  end

  it "refuses a Case whose closing exchange half falls under two points" do
    under = {"per_day" => 10, "exchange_pool" => 2, "exhibit_price" => 1,
             "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 1}

    expect { described_class.call(authored(budget: under)) }
      .to raise_error(described_class::InvalidCase, /exchange/)
  end

  it "refuses a Budget value authored as a string rather than a number" do
    quoted = {"per_day" => 10, "exchange_pool" => "2", "exhibit_price" => 1,
              "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: quoted)) }
      .to raise_error(described_class::InvalidCase, /not a whole number of points/)
  end

  # It would otherwise import cleanly and trip a `day_budgets` CHECK on the
  # first closing Day, mid-Simulation.
  it "refuses a negative closing preparation half" do
    negative = {"per_day" => 10, "exchange_pool" => 2, "exhibit_price" => 1,
                "closing_knee" => 0.60, "closing_preparation" => -2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: negative)) }
      .to raise_error(described_class::InvalidCase, /less than nothing/)
  end

  it "refuses a closing knee that is not a fraction of the Simulation" do
    past_the_end = {"per_day" => 10, "exchange_pool" => 2, "exhibit_price" => 1,
                    "closing_knee" => 6, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: past_the_end)) }
      .to raise_error(described_class::InvalidCase, /not a fraction of the Simulation/)
  end

  # The taper takes a Budget cut out of the preparation half and never out of
  # the brake, so this authors a negative preparation half on Day 1.
  it "refuses a Budget smaller than its own exchange half" do
    inverted = {"per_day" => 1, "exchange_pool" => 2, "exhibit_price" => 1,
                "closing_knee" => 0.60, "closing_preparation" => 2, "closing_exchange" => 3}

    expect { described_class.call(authored(budget: inverted)) }
      .to raise_error(described_class::InvalidCase, /leaving nothing to prepare with/)
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

  describe "the Clients an Exhibit targets" do
    it "loads one for each Side, with its bound held in money" do
      version = described_class.call(Rails.root.join("db/cases/reference.yml"))

      expect(version.clients.map(&:role)).to match_array(Side::ROLES)
      expect(version.clients.find_by!(role: Side::PLAINTIFF).bound_cents).to eq(40_000_00)
      expect(version.clients.find_by!(role: Side::DEFENDANT).bound_cents).to eq(60_000_00)
    end

    it "refuses a Case that authors a Client for only one Side" do
      lonely = {"plaintiff" => {"bound" => 40_000, "opening_statement" => "Alone."}}

      expect { described_class.call(authored(clients: lonely)) }
        .to raise_error(described_class::InvalidCase, /one for each of/)
    end

    it "refuses a Client with no bound to be moved by" do
      unmovable = {
        "plaintiff" => {"bound" => 0, "opening_statement" => "Immovable."},
        "defendant" => {"bound" => 60_000, "opening_statement" => "Quietly."}
      }

      expect { described_class.call(authored(clients: unmovable)) }
        .to raise_error(described_class::InvalidCase, /whole amount of money/)
    end

    # One of the Morning Briefing's what-you-start-with sections, so a Case
    # without it imports into a briefing with a hole in it.
    it "loads what each Client says they want on the Day their Team sits down" do
      version = described_class.call(Rails.root.join("db/cases/reference.yml"))

      expect(version.clients.find_by!(role: Side::PLAINTIFF).opening_statement)
        .to include("Eleven years")
      expect(version.clients.find_by!(role: Side::DEFENDANT).opening_statement)
        .to include("closed quietly")
    end

    it "refuses a Client with no opening statement" do
      silent = {
        "plaintiff" => {"bound" => 40_000},
        "defendant" => {"bound" => 60_000, "opening_statement" => "Quietly."}
      }

      expect { described_class.call(authored(clients: silent)) }
        .to raise_error(described_class::InvalidCase, /no opening statement/)
    end
  end

  # The Terms Board's third track, and what lets the board exist without ever
  # showing Par. Not the private valuation the same Client puts on the same
  # Term: that is what an Offer is scored by and no student ever sees it.
  describe "what a Client says they want" do
    def wanting(plaintiff, defendant = {"money" => 50_000})
      {
        "plaintiff" => {
          "bound" => 40_000, "opening_statement" => "Loudly.", "aspirations" => plaintiff
        },
        "defendant" => {
          "bound" => 60_000, "opening_statement" => "Quietly.", "aspirations" => defendant
        }
      }
    end

    it "loads an aspiration per Term, in the money the bound is authored in" do
      version = described_class.call(Rails.root.join("db/cases/reference.yml"))
      plaintiff = version.clients.find_by!(role: Side::PLAINTIFF)

      expect(plaintiff.aspirations.joins(:case_term).pluck("case_terms.key", :amount_cents))
        .to match_array([["money", 250_000_00], ["apology", nil], ["reinstatement", nil]])
    end

    # A Client wanting an apology wants an apology, and there is no figure to
    # put on it.
    it "loads a Term wanted without a figure carrying none" do
      version = described_class.call(authored(clients: wanting({"reinstatement" => nil})))
      aspiration = version.clients.find_by!(role: Side::PLAINTIFF).aspirations.sole

      expect(aspiration.case_term.key).to eq("reinstatement")
      expect(aspiration).not_to be_money
    end

    # Sparse on purpose: a Term absent here is one this Client is indifferent
    # about, and its track carries the two live positions and no marker.
    it "leaves the Terms a Client is indifferent about unauthored" do
      version = described_class.call(authored(clients: wanting({"money" => 90_000})))
      plaintiff = version.clients.find_by!(role: Side::PLAINTIFF)

      expect(plaintiff.aspirations.count).to eq(1)
      expect(version.terms.count).to eq(2)
    end

    it "accepts a Client who says nothing about any Term" do
      version = described_class.call(authored(clients: wanting(nil, nil)))

      expect(version.clients.flat_map(&:aspirations)).to be_empty
    end

    it "refuses an aspiration for a Term this Case authors none of" do
      expect { described_class.call(authored(clients: wanting({"a_pony" => nil}))) }
        .to raise_error(described_class::InvalidCase, /authors no Term for/)
    end

    it "refuses an amount that is not whole money" do
      expect { described_class.call(authored(clients: wanting({"money" => 0}))) }
        .to raise_error(described_class::InvalidCase, /neither a whole amount of money/)
    end

    it "replaces the aspirations of a draft, as it does the Terms" do
      draft = {"published" => false, "version" => "0.1.0"}
      described_class.call(authored(clients: wanting({"money" => 90_000}), **draft))
      version = described_class.call(authored(clients: wanting({"reinstatement" => nil}), **draft))

      expect(version.clients.find_by!(role: Side::PLAINTIFF).aspirations.sole.case_term.key)
        .to eq("reinstatement")
    end
  end

  describe "the Terms vocabulary" do
    it "loads the Terms an Offer is built from" do
      version = described_class.call(Rails.root.join("db/cases/reference.yml"))

      expect(version.terms.map(&:key)).to include("money", "reinstatement", "policy_change")
    end

    it "refuses a Case that authors no Terms" do
      expect { described_class.call(authored(terms: [])) }
        .to raise_error(described_class::InvalidCase, /terms/)
    end

    it "refuses a Terms list that is not a list of Terms" do
      expect { described_class.call(authored(terms: [{"key" => "money"}])) }
        .to raise_error(described_class::InvalidCase, /no terms for an Offer/)
    end

    it "refuses a Term authored twice, because Terms are atomic" do
      expect { described_class.call(authored(terms: %w[money money])) }
        .to raise_error(described_class::InvalidCase, /Terms are atomic/)
    end
  end

  # Provenance's other two authored kinds: what a Team walks in with. The xor
  # against the Action menu is what makes *doors visible, contents hidden*
  # checkable — nothing a Team starts with can also be something it finds.
  describe "the documents in hand at the open" do
    let(:reference) { described_class.call(Rails.root.join("db/cases/reference.yml")) }

    def a_letter(**overrides)
      {"the_letter_they_kept" => {
        "hand" => "plaintiff", "title" => "The letter they kept", "body" => "Prose."
      }.merge(overrides.transform_keys(&:to_s))}
    end

    it "loads a document in both Sides' hands, waiting behind nothing" do
      letter = reference.documents.find_by!(identifier: "the_termination_letter")

      expect(letter.provenance).to eq(CaseDocument::BOTH_SIDES)
      expect(letter.case_action).to be_nil
      expect(letter).to be_in_hand_at_the_open
    end

    it "loads a document in one Side's hand" do
      notes = reference.documents.find_by!(identifier: "the_claimants_own_notes")

      expect(notes.provenance).to eq(Side::PLAINTIFF)
      expect(notes).to be_held_at_the_open_by(Side::PLAINTIFF)
      expect(notes).not_to be_held_at_the_open_by(Side::DEFENDANT)
    end

    it "leaves a document behind an Action discoverable rather than in a hand" do
      deposition = reference.documents.find_by!(identifier: "deposition_of_the_supervisor")

      expect(deposition.provenance).to eq(CaseDocument::DISCOVERABLE)
      expect(deposition).not_to be_in_hand_at_the_open
    end

    it "refuses a document that names both an Action and a hand" do
      expect { described_class.call(authored(documents: a_letter(action: "depose_witness"))) }
        .to raise_error(described_class::InvalidCase, /both an action and a hand/)
    end

    it "refuses a document that names neither" do
      expect { described_class.call(authored(documents: a_letter(hand: nil))) }
        .to raise_error(described_class::InvalidCase, /neither an action nor a hand/)
    end

    it "refuses a hand nobody holds" do
      expect { described_class.call(authored(documents: a_letter(hand: "the_press"))) }
        .to raise_error(described_class::InvalidCase, /not a hand at the open/)
    end

    # Ammunition a Team walks in with is a position the Case authored and Par is
    # authored against it.
    it "loads a favorable Exhibit in hand at the open" do
      exhibit = {"target" => "defendant", "shift" => 0.15, "bears_on" => %w[money]}
      version = described_class.call(authored(documents: a_letter(exhibit: exhibit)))
      letter = version.documents.find_by!(identifier: "the_letter_they_kept")

      expect(letter).to be_exhibit
      expect(letter.exhibit_target_role).to eq(Side::DEFENDANT)
    end

    # Its shift would land before the first Day is played, spending the Client's
    # bound with no Docket line behind it and no beat to read it in.
    it "refuses an unfavorable Exhibit in hand at the open" do
      exhibit = {"target" => "plaintiff", "shift" => 0.15, "bears_on" => %w[money]}

      expect { described_class.call(authored(documents: a_letter(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /before the first Day is played/)
    end

    # A document in both hands is in the hand of whichever Client it would
    # target, so it may carry no Exhibit at all.
    it "refuses any Exhibit on a document in both Sides' hands" do
      exhibit = {"target" => "defendant", "shift" => 0.15, "bears_on" => %w[money]}
      both = a_letter(hand: "both_sides", exhibit: exhibit)

      expect { described_class.call(authored(documents: both)) }
        .to raise_error(described_class::InvalidCase, /before the first Day is played/)
    end
  end

  describe "the documents waiting behind an Action" do
    let(:reference) { described_class.call(Rails.root.join("db/cases/reference.yml")) }

    it "loads each behind the Action that discovers it" do
      deposition = reference.documents.find_by!(identifier: "deposition_of_the_supervisor")

      expect(deposition.case_action.kind).to eq(CaseAction::DEPOSE_WITNESS)
      expect(deposition.title).to eq("Deposition of the plant supervisor")
      expect(deposition.body).to include("signed acknowledgement")
    end

    it "loads the Exhibit property a document carries, with the Terms it bears on" do
      deposition = reference.documents.find_by!(identifier: "deposition_of_the_supervisor")

      expect(deposition).to be_exhibit
      expect(deposition.exhibit_target_role).to eq(Side::PLAINTIFF)
      expect(deposition.exhibit_shift_fraction).to eq(0.25)
      expect(deposition.bears_on_terms.map(&:key)).to match_array(%w[money reinstatement])
    end

    it "leaves a document that carries no Exhibit carrying none" do
      memorandum = reference.documents.find_by!(identifier: "memorandum_on_comparable_awards")

      expect(memorandum).not_to be_exhibit
      expect(memorandum.bears_on_terms).to be_empty
    end

    # A tip, hidden behind whichever Action or Exhibit each example is about.
    def a_tip(**overrides)
      {"an_anonymous_tip" => {
        "action" => "depose_witness", "title" => "An anonymous tip", "body" => "Prose."
      }.merge(overrides.transform_keys(&:to_s))}
    end

    it "refuses a document that waits behind no Action, because Provenance is checkable" do
      expect { described_class.call(authored(documents: a_tip(action: "subpoena_the_mayor"))) }
        .to raise_error(described_class::InvalidCase, /not on this Case's Action menu/)
    end

    it "refuses a document authored without a title or a body" do
      expect { described_class.call(authored(documents: a_tip(body: nil))) }
        .to raise_error(described_class::InvalidCase, /without title, body/)
    end

    it "refuses an Exhibit missing a target, a shift or the Terms it bears on" do
      exhibit = {"target" => "plaintiff", "shift" => 0.25}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /without target, shift, bears_on/)
    end

    it "refuses an Exhibit pointing at somebody who is not a Client" do
      exhibit = {"target" => "the_judge", "shift" => 0.25, "bears_on" => %w[money]}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /which is not a Client/)
    end

    # Player-caused movement is a ratchet: an Exhibit only ever moves a
    # reservation point toward settleability.
    it "refuses an Exhibit whose shift reaches back outward" do
      exhibit = {"target" => "plaintiff", "shift" => -0.25, "bears_on" => %w[money]}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /toward settleability/)
    end

    # A lone Term written without a list passes every other check, and would
    # otherwise reach the importer to be iterated as a String.
    it "refuses an Exhibit bearing on a Term written without a list around it" do
      exhibit = {"target" => "plaintiff", "shift" => 0.25, "bears_on" => "money"}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /not a list of the Terms it bears on/)
    end

    it "refuses an Exhibit bearing on something that is not a Term at all" do
      exhibit = {"target" => "plaintiff", "shift" => 0.25, "bears_on" => [{"key" => "money"}]}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /not a list of the Terms it bears on/)
    end

    it "refuses an Exhibit bearing on a Term the Case authors no vocabulary for" do
      exhibit = {"target" => "plaintiff", "shift" => 0.25, "bears_on" => %w[a_pony]}

      expect { described_class.call(authored(documents: a_tip(exhibit: exhibit))) }
        .to raise_error(described_class::InvalidCase, /authors no Term for/)
    end

    it "replaces the documents of a draft, as it does the Action menu" do
      described_class.call(authored(published: false))

      version = described_class.call(
        authored(published: false, documents: a_tip(title: "A second deposition"))
      )

      expect(version.documents.map(&:identifier)).to eq(["an_anonymous_tip"])
      expect(CaseDocument.count).to eq(1)
      expect(CaseDocumentTerm.count).to be_zero
    end
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
