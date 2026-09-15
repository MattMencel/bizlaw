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
    # the Instructor's act, and the third tab is where it is granted from.
    puts "  #{"Day #{Demo::Seed::DEMO_DAY}, the second tab:".ljust(28)}" \
         "#{seed.url_for(Demo::Seed::DEMO, Side::DEFENDANT)}"
    # The third. The Instructor is on no Side, so what is at this address is the
    # minute rather than a file — one line per Team, and the one act they take
    # inside a running Day.
    puts "  #{"Day #{Demo::Seed::DEMO_DAY}, the instructor:".ljust(28)}" \
         "#{seed.url_for(Demo::Seed::DEMO, Demo::Seat::INSTRUCTOR)}"
    puts "  #{"Day 1, the cold open:".ljust(28)}#{seed.url_for(Demo::Seed::COLD_OPEN)}"
  end
end
