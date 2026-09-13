# frozen_string_literal: true

# PROTOTYPE (#373) — the third page state.
#
#   bin/rails runner prototype/term-sheet-redline/stage.rb
#
# `rake demo:seed` hands the player a Day 3 on which he has taken no position
# at all, so every one of *our* slots on the term sheet is silent and the
# redline has only one side to it. That is the real Day 3 and it is worth
# looking at — but it cannot answer whether a struck figure with ours written
# in beside it beats two columns, because there is never anything written in.
#
# This puts a draft on his table through the real seam. Four of the seven Terms
# are touched, so between them the sheet carries every combination the register
# has to render:
#
#   money          theirs $40,000, ours $150,000   → struck, and written over
#   apology        theirs silent, ours no figure   → written in, nothing struck
#   nda            theirs no figure, ours silent   → struck, and a blank
#   reinstatement  theirs silent, ours no figure   → written in, and a margin
#   the other three                                → nobody has tabled them
#
# `rake demo:seed` undoes it.

simulation = Demo::Seed.simulation("day-3")
side = simulation.plaintiff_side
day = simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY)
player = User.find_by!(email: Demo::Seed::PLAYER_EMAIL)

Offers::Stage.call(
  side: side,
  day: day,
  by: player,
  terms: {"money" => 150_000_00, "apology" => nil, "reinstatement" => nil},
  note: "Without prejudice. This is a counter, not an acceptance."
)

puts "Staged the plaintiff's Day #{day.ordinal} draft. http://localhost:3000/demo/day-3"
