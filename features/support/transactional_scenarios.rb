# frozen_string_literal: true

# Each scenario runs inside a transaction that is rolled back at its end.
#
# cucumber-rails only cleans the database through DatabaseCleaner, which this
# repo does not carry: with an append-only ledger there is nothing to truncate
# between scenarios that a rolled-back transaction does not already undo. A
# scenario driving a browser would need a strategy this cannot express, since
# the server thread holds its own connection — reach for one when a scenario
# actually does.
Around do |_scenario, block|
  ActiveRecord::Base.transaction do
    block.call
    raise ActiveRecord::Rollback
  end
end
