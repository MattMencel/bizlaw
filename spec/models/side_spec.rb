# frozen_string_literal: true

require "rails_helper"

RSpec.describe Side do
  it "holds one Side per role in a Simulation, so there can never be a third" do
    simulation = a_simulation

    expect { simulation.sides.create!(role: Side::PLAINTIFF) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end

  it "is capped at two by unique index, not only by validation" do
    simulation = a_simulation
    third = simulation.sides.build(role: Side::PLAINTIFF, organization_id: simulation.organization_id)

    expect { third.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect(simulation.sides.reload.count).to eq(2)
  end

  it "refuses a role the dispute does not have" do
    simulation = a_simulation

    expect { simulation.sides.create!(role: "arbitrator") }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
