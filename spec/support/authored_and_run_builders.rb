# frozen_string_literal: true

# Builders for the authored and run-shaped rows the Day's economy hangs off.
# They are plain creates rather than factories: this ticket's specs need four
# objects, and a factory library is added when a ticket needs one.
module AuthoredAndRunBuilders
  def an_organization(name: "Western Illinois University")
    Organization.create!(name: name)
  end

  def a_section(organization: an_organization, name: "LAW 301, Fall")
    Section.create!(organization: organization, name: name)
  end

  def a_case_version(days: 10, published: true, identifier: "bizlaw/reference", version: "1.0.0")
    authored = Case.find_or_create_by!(identifier: identifier) do |record|
      record.name = "The Reference Case"
      record.licence = "Apache-2.0"
    end
    authored.versions.create!(version: version, published_at: (Time.current if published)).tap do |pinned|
      days.times do |index|
        pinned.calendar_days.create!(
          ordinal: index + 1,
          in_fiction_date: Date.new(2026, 3, 2) + index
        )
      end
    end
  end

  def a_simulation(section: a_section, case_version: a_case_version)
    Simulations::Create.call(section: section, case_version: case_version)
  end
end

RSpec.configure do |config|
  config.include AuthoredAndRunBuilders
end
