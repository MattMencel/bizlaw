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

  def an_organization(name: "Western Illinois University")
    Organization.create!(name: name)
  end

  def a_section(organization: an_organization, name: "LAW 301, Fall")
    Section.create!(organization: organization, name: name)
  end

  # The reference Case's authored Budget: 10 points a Day, an exchange half of
  # two, and a knee at three fifths past which the Day is 2 and 3.
  def a_case_version(days: 10, published: true, identifier: "bizlaw/reference", version: "1.0.0",
    budget_per_day: 10, exchange_pool: 2, closing_knee: 0.60, closing_preparation: 2,
    closing_exchange: 3)
    authored = Case.find_or_create_by!(identifier: identifier) do |record|
      record.name = "The Reference Case"
      record.licence = "Apache-2.0"
    end
    authored.versions.create!(
      version: version,
      published_at: (Time.current if published),
      budget_per_day: budget_per_day,
      exchange_pool: exchange_pool,
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
