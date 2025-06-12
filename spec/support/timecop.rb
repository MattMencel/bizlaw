# frozen_string_literal: true

require 'timecop'

RSpec.configure do |config|
  # Include Timecop methods at the top level
  config.include Module.new {
    def freeze_time(*args, &block)
      Timecop.freeze(*args, &block)
    end

    def travel(*args, &block)
      Timecop.travel(*args, &block)
    end

    def travel_to(*args, &block)
      Timecop.travel(*args, &block)
    end
  }

  config.after do
    Timecop.return
  end
end
