# frozen_string_literal: true

require "timecop"

RSpec.configure do |config|
  # Include Timecop methods at the top level
  config.include Module.new {
    def freeze_time(*, &)
      Timecop.freeze(*, &)
    end

    def travel(*, &)
      Timecop.travel(*, &)
    end

    def travel_to(*, &)
      Timecop.travel(*, &)
    end
  }

  config.after do
    Timecop.return
  end
end
