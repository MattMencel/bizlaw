# frozen_string_literal: true

require "rails_helper"

# ADR 0002: everything that moves is derived on read, and there is no status
# column anywhere. `days.closed_at` and `case_versions.published_at` are the
# only shape a run's state takes on the tables this ticket adds.
RSpec.describe "the tables of the Simulation skeleton" do
  let(:tables) do
    %w[
      cases case_versions case_calendar_days case_actions
      case_clients case_terms case_documents case_document_terms
      organizations sections simulations sides days day_budgets
      users docket_entries case_file_documents client_shifts
      day_commitments
    ]
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
