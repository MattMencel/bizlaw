# frozen_string_literal: true

namespace :demo do
  desc "Lay down the playable Day 3 and the Day 1 cold open (resets its own demo Organization)"
  task seed: :environment do
    abort "demo:seed does not run in production" if Rails.env.production?

    seed = Demo::Seed.new
    seed.call

    puts "Seeded #{Demo::Seed::ORGANIZATION} / #{Demo::Seed::SECTION}"
    puts "  #{"Day #{Demo::Seed::DEMO_DAY}, the plaintiff's:".ljust(28)}" \
         "#{seed.url_for(Demo::Seed::DEMO)}"
    # The second tab. It acts as the other firm, which is where the Acceptance
    # comes from without a second live player — so its address is printed rather
    # than constructed by hand mid-demo. The waiver is not its to grant: that is
    # the Instructor's act, seated separately and with no page yet.
    puts "  #{"Day #{Demo::Seed::DEMO_DAY}, the second tab:".ljust(28)}" \
         "#{seed.url_for(Demo::Seed::DEMO, Side::DEFENDANT)}"
    puts "  #{"Day 1, the cold open:".ljust(28)}#{seed.url_for(Demo::Seed::COLD_OPEN)}"
  end
end
