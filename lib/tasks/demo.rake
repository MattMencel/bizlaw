# frozen_string_literal: true

namespace :demo do
  desc "Lay down the playable Day 3 and the Day 1 cold open (resets its own demo Organization)"
  task seed: :environment do
    abort "demo:seed does not run in production" if Rails.env.production?

    seed = Demo::Seed.new
    seed.call

    puts "Seeded #{Demo::Seed::ORGANIZATION} / #{Demo::Seed::SECTION}"
    puts "  #{"Day #{Demo::Seed::DEMO_DAY}, the plaintiff's:".ljust(24)}" \
         "#{seed.url_for(Demo::Seed::DEMO)}"
    puts "  #{"Day 1, the cold open:".ljust(24)}#{seed.url_for(Demo::Seed::COLD_OPEN)}"
  end
end
