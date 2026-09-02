# frozen_string_literal: true

require "rails_helper"

RSpec.describe Day do
  it "is open until it is closed, derived from closed_at" do
    day = a_simulation.days.first

    expect(day).to be_open
    expect(day).not_to be_closed

    day.update!(closed_at: Time.current)

    expect(day).to be_closed
    expect(day).not_to be_open
  end

  it "scopes open and closed Days from the same column" do
    simulation = a_simulation
    simulation.days.first.update!(closed_at: Time.current)

    expect(simulation.days.open.count).to eq(9)
    expect(simulation.days.closed.map(&:ordinal)).to eq([1])
  end

  it "holds one Day per ordinal in a Simulation" do
    simulation = a_simulation

    expect {
      simulation.days.create!(ordinal: 1, in_fiction_date: Date.new(2027, 1, 1))
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
