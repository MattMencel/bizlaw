# frozen_string_literal: true

module Demo
  # The Instructor releases the Second for one Team for one Day.
  #
  # There is no quote and no confirmation, and that is the rule rather than a
  # shortcut: `Days::Command`'s two verbs exist to confirm a spend, and a waiver
  # has no cost to confirm — which is why `Offers::WaiveSecond` sits beside that
  # seam rather than inside it. What a confirmation would be protecting against
  # is an irreversible charge, and nothing here is charged.
  #
  # It is irreversible all the same — there is no revoking one — but the act it
  # enables is the Team's own and still has to be confirmed by them, so the
  # reader who cannot take it back is not the reader who pays for it.
  #
  # What arrives is the Side's role and the Day. The role rather than a row id
  # for the reason the sheet names Terms by their authored key: `demo:seed`
  # resets, and every id under this page moves with it.
  class WaiversController < SeatedController
    def create
      instructor = resolve_instructor
      simulation = Seed.simulation(params[:run])
      side = simulation.sides.find_by(role: params[:role])
      day = simulation.days.find_by(ordinal: params[:day])
      return no_page if side.nil? || day.nil?

      Offers::WaiveSecond.call(side: side, day: day, by: instructor.user)

      redirect_to minute_path
    rescue Offers::DayClosed
      # The Day ended under the minute — the other Side committed, or a deadline
      # fired, in the window between this page's render and this press. It is
      # already a refusal the engine names, so it comes back as the engine's own
      # symbol and becomes a sentence in the page, the way a student's does.
      carry_refusal(WAIVER_REFUSAL, instructor,
        {"role" => params[:role].to_s, "reason" => :the_day_has_closed.to_s})
      redirect_to minute_path
    rescue ArgumentError
      no_page
    end
  end
end
