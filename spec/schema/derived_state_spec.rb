# frozen_string_literal: true

require "rails_helper"

# ADR 0002: everything that moves is derived on read, and there is no status
# column anywhere. `days.closed_at` and `case_versions.published_at` are the
# only shape a run's state takes on the tables this ticket adds.
RSpec.describe "the tables of the Simulation skeleton" do
  # Enumerated from the schema rather than listed here. A maintained list drifts
  # silently, which is the failure this rule exists to prevent — and it had:
  # `committed_offer_terms`, `offer_acceptances` and `case_client_aspirations`
  # were all added without reaching the list, so the rule stopped covering them
  # the moment they arrived. `spec/models/retention_spec.rb` makes the same
  # argument for the sibling rule and enumerates the same way.
  let(:tables) do
    ActiveRecord::Base.connection.tables - %w[ar_internal_metadata schema_migrations]
  end

  it "carry no status column" do
    offenders = tables.flat_map { |table|
      ActiveRecord::Base.connection.columns(table)
        .map(&:name)
        .grep(/\A(status|state)\z/)
        .map { |column| "#{table}.#{column}" }
    }

    expect(offenders).to be_empty
  end

  it "carry no soft-deletion column" do
    offenders = tables.flat_map { |table|
      ActiveRecord::Base.connection.columns(table)
        .map(&:name)
        .grep(/\Adeleted_at\z/)
        .map { |column| "#{table}.#{column}" }
    }

    expect(offenders).to be_empty
  end
end
