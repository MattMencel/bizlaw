# frozen_string_literal: true

require "rails_helper"

# The run's own seed: what makes two Simulations of one Case hear their Clients
# in different orders. Written once by `Simulations::Create` and never after —
# a Consult's memo is re-readable forever and must read back the variant the
# Client actually spoke, so a seed that moved would rewrite history a Docket
# line already claims.
RSpec.describe "the Simulation seed" do
  it "arrives with the run" do
    expect(a_simulation.seed).to be_present
  end

  # Two runs of one Case are the only place a shared seed would show, and the
  # thing #334 exists to stop: every Team on a Case hearing its Client's lines
  # in one fixed order.
  it "differs between two runs of one Case" do
    case_version = a_case_version
    section = a_section

    seeds = Array.new(4) {
      Simulations::Create.call(section: section, case_version: case_version).seed
    }

    expect(seeds.uniq.size).to eq(4)
  end

  it "cannot be reassigned through the model" do
    simulation = a_simulation
    was = simulation.seed

    expect { simulation.update!(seed: "rewritten") }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(simulation.reload.seed).to eq(was)
  end

  # `attr_readonly` covers the ordinary path. The trigger is what holds when
  # something skips the model — ADR 0002 puts an invariant in the database
  # wherever it fits in one, and this one fits in one.
  #
  # Raw SQL rather than the `update_column` the other constraint specs skip the
  # model with: `attr_readonly` refuses that one too, so it never reaches the
  # trigger and would prove the Ruby guard twice instead of the database's.
  it "is refused by the database on an UPDATE that skips the model" do
    simulation = a_simulation

    expect {
      ActiveRecord::Base.connection.execute(
        "UPDATE simulations SET seed = 'rewritten' WHERE id = #{simulation.id}"
      )
    }.to raise_error(ActiveRecord::StatementInvalid, /simulations_seed_is_written_once/)
    expect(simulation.reload.seed).not_to eq("rewritten")
  end

  # An UPDATE that touches other columns and leaves the seed alone is ordinary.
  it "does not stand in the way of an update that leaves it alone" do
    simulation = a_simulation

    expect {
      ActiveRecord::Base.connection.execute(
        "UPDATE simulations SET updated_at = updated_at WHERE id = #{simulation.id}"
      )
    }.not_to raise_error
  end
end
