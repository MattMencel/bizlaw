# frozen_string_literal: true

# Builders for the authored and run-shaped rows the Day's economy hangs off.
# They are plain creates rather than factories: this ticket's specs need four
# objects, and a factory library is added when a ticket needs one.
module AuthoredAndRunBuilders
  # The reference Case's Action menu: cost and lead time in Days, all of it on
  # the preparation half. Nothing draws on the exchange half until an Offer can
  # commit.
  REFERENCE_ACTIONS = {
    CaseAction::CONSULT_CLIENT => [1, 0],
    CaseAction::REQUEST_DOCUMENTS => [2, 1],
    CaseAction::RESEARCH_PRECEDENT => [2, 1],
    CaseAction::MANAGE_PRESS => [2, 1],
    CaseAction::DEPOSE_WITNESS => [3, 2],
    CaseAction::RETAIN_EXPERT => [5, 2]
  }.freeze

  # The Terms vocabulary an Offer is built from and an Exhibit bears on.
  REFERENCE_TERMS = %w[
    money apology nda reinstatement training reference_letter policy_change
  ].freeze

  # The reference Case's documents in hand at the open, waiting behind nothing.
  # Neither carries an Exhibit, so the Exhibit affordances stay unavailable on
  # Day 1 and appear the moment preparation first yields one.
  REFERENCE_OPEN_HAND = {
    "the_termination_letter" => {
      hand: CaseDocument::BOTH_SIDES,
      title: "The termination letter"
    },
    "the_claimants_own_notes" => {
      hand: Side::PLAINTIFF,
      title: "The claimant's own notes"
    }
  }.freeze

  # What each Client says out loud about the Terms, sparse and immobile. A Term
  # absent here is one that Client is indifferent about. Held in cents, as the
  # column is; the authored file writes whole money.
  REFERENCE_ASPIRATIONS = {
    Side::PLAINTIFF => {"money" => 250_000_00, "apology" => nil, "reinstatement" => nil},
    Side::DEFENDANT => {"money" => 25_000_00, "nda" => nil}
  }.freeze

  # What each Client says over the executed instrument, keyed on which Side
  # accepted. Two lines per Client and no variants, as `db/cases/reference.yml`
  # authors them — abbreviated here for the same reason the opening statements
  # are: a builder needs the shape, not the prose.
  REFERENCE_SETTLEMENT = {
    Side::PLAINTIFF => {
      CaseClient::TOOK_IT => "It is not everything I asked for. I decided it was enough.",
      CaseClient::HAD_IT_TAKEN => "They signed it. My number, my words, their name underneath."
    },
    Side::DEFENDANT => {
      CaseClient::TOOK_IT => "We take their paper, and we take it today.",
      CaseClient::HAD_IT_TAKEN => "They signed ours. Get it filed, and keep it quiet."
    }
  }.freeze

  # The seeds `db/cases/reference.yml` authors, verbatim, because they are the
  # one pair `Cases::Import` compares: a builder that invented its own could
  # hand two Clients one face and no spec here would notice.
  REFERENCE_PORTRAIT_SEEDS = {
    Side::PLAINTIFF => "greaves-plaintiff",
    Side::DEFENDANT => "hollis-defendant"
  }.freeze

  # The reference Case's documents waiting behind the Action that discovers
  # them. Whether an Exhibit is favorable is not authored: the deposition points
  # at the plaintiff Client, so the defendant holds it to play and the plaintiff
  # has it land on them the moment they find it.
  #
  # These mirror `db/cases/reference.yml` down to the titles, so that a spec and
  # a Cucumber walk — which imports the file itself — are reading one Case and
  # not two. A builder rather than an import because a spec varies the Budget,
  # the Day count and publication, which an authored file does not.
  REFERENCE_DOCUMENTS = {
    "deposition_of_the_supervisor" => {
      action: CaseAction::DEPOSE_WITNESS,
      title: "Deposition of the plant supervisor",
      exhibit_target_role: Side::PLAINTIFF,
      exhibit_shift_fraction: 0.25,
      bears_on: %w[money reinstatement]
    },
    "personnel_file" => {
      action: CaseAction::REQUEST_DOCUMENTS,
      title: "The claimant's personnel file",
      exhibit_target_role: Side::DEFENDANT,
      exhibit_shift_fraction: 0.20,
      bears_on: %w[money apology]
    },
    "memorandum_on_comparable_awards" => {
      action: CaseAction::RESEARCH_PRECEDENT,
      title: "Memorandum on comparable awards",
      exhibit_target_role: nil,
      exhibit_shift_fraction: nil,
      bears_on: []
    }
  }.freeze

  def an_organization(name: "Western Illinois University")
    Organization.create!(name: name)
  end

  def a_section(organization: an_organization, name: "LAW 301, Fall")
    Section.create!(organization: organization, name: name)
  end

  # The reference Case's authored Budget: 10 points a Day, an exchange half of
  # two, and a knee at three fifths past which the Day is 2 and 3.
  def a_case_version(days: 10, published: true, identifier: "bizlaw/reference", version: "1.0.0",
    budget_per_day: 10, exchange_pool: 2, exhibit_price: 1, closing_knee: 0.60,
    closing_preparation: 2, closing_exchange: 3)
    authored = Case.find_or_create_by!(identifier: identifier) do |record|
      record.name = "The Reference Case"
      record.licence = "Apache-2.0"
    end
    authored.versions.create!(
      version: version,
      published_at: (Time.current if published),
      budget_per_day: budget_per_day,
      exchange_pool: exchange_pool,
      exhibit_price: exhibit_price,
      closing_knee: closing_knee,
      closing_preparation: closing_preparation,
      closing_exchange: closing_exchange
    ).tap do |pinned|
      REFERENCE_ACTIONS.each do |kind, (cost, lead_time_days)|
        pinned.actions.create!(
          kind: kind, cost: cost, lead_time_days: lead_time_days,
          half: DayBudget::PREPARATION
        )
      end
      days.times do |index|
        pinned.calendar_days.create!(
          ordinal: index + 1,
          in_fiction_date: Date.new(2026, 3, 2) + index
        )
      end
      an_authored_dispute(pinned)
    end
  end

  # The Clients an Exhibit targets, the Terms it bears on, and the documents
  # waiting behind the Action menu above.
  def an_authored_dispute(pinned)
    vocabulary = REFERENCE_TERMS.index_with { |key| pinned.terms.create!(key: key) }
    {
      Side::PLAINTIFF => [40_000_00, "Eleven years, and they walked me out like a thief."],
      Side::DEFENDANT => [60_000_00, "We followed the policy. I want this closed quietly."]
    }.each do |role, (bound_cents, opening_statement)|
      client = pinned.clients.create!(
        role: role, bound_cents: bound_cents, opening_statement: opening_statement,
        portrait_seed: REFERENCE_PORTRAIT_SEEDS.fetch(role),
        **settlement_lines_for(role)
      )
      REFERENCE_ASPIRATIONS.fetch(role).each do |key, amount_cents|
        client.aspirations.create!(case_term: vocabulary.fetch(key), amount_cents: amount_cents)
      end
    end

    REFERENCE_OPEN_HAND.each do |identifier, authored|
      pinned.documents.create!(
        provenance: authored.fetch(:hand),
        case_version: pinned,
        identifier: identifier,
        title: authored.fetch(:title),
        body: "Authored prose for #{identifier}."
      )
    end

    REFERENCE_DOCUMENTS.each do |identifier, authored|
      document = pinned.documents.create!(
        case_action: pinned.actions.find_by!(kind: authored.fetch(:action)),
        provenance: CaseDocument::DISCOVERABLE,
        identifier: identifier,
        title: authored.fetch(:title),
        body: "Authored prose for #{identifier}.",
        exhibit_target_role: authored.fetch(:exhibit_target_role),
        exhibit_shift_fraction: authored.fetch(:exhibit_shift_fraction)
      )
      authored.fetch(:bears_on).each do |key|
        document.document_terms.create!(case_term: vocabulary.fetch(key))
      end
    end
  end

  # The settlement pair as the columns that hold it, so a builder and the
  # importer name the authored keys once between them.
  def settlement_lines_for(role)
    CaseClient::SETTLEMENT_LINES.to_h do |acceptance_role, column|
      [column, REFERENCE_SETTLEMENT.fetch(role).fetch(acceptance_role)]
    end
  end

  def a_user(organization: an_organization, name: "Dana Okafor", email: "dana@example.edu")
    User.create!(organization: organization, name: name, email: email)
  end

  def a_simulation(section: a_section, case_version: a_case_version)
    Simulations::Create.call(section: section, case_version: case_version)
  end
end

RSpec.configure do |config|
  config.include AuthoredAndRunBuilders
end
