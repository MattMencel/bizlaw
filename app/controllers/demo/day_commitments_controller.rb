# frozen_string_literal: true

module Demo
  # Committing the Day without an Offer: the Team declares itself finished with
  # it, and if the other Side already has, the Day closes (#396).
  #
  # It is one player's call. There is no Second and no waiver, because
  # committing locks nothing — a Side that committed can still spend, stage and
  # send until the Day closes — so there is nothing for a teammate to confirm.
  # It costs nothing either, which is why it reaches `Days::Commit` rather than
  # `Days::Command`.
  #
  # Like the spend it carries the Day the page read rather than asking again:
  # between the render and the press the Day can close, and committing the next
  # one would commit a Day the reader never saw. The seam refuses the closed one
  # instead.
  class DayCommitmentsController < SeatedController
    def create
      seated = resolve
      return if performed?

      day = quoted_day(seated)
      return no_page if day.nil?

      Days::Commit.call(side: seated.side, day: day, by: seated.user)

      redirect_to draft_path(seated)
    rescue Days::Commit::DayClosed, Simulation::AlreadySettled
      # The seam's own list names the reason. A close that raced the insert has
      # already been reloaded underneath it, so asking again answers truly.
      reason = Days::Commit.refusal_for(side: seated.side, day: day, by: seated.user)
      carry_refusal(DAY_COMMIT_REFUSAL, seated, {"reason" => reason.to_s})
      redirect_to draft_path(seated)
    rescue ArgumentError
      no_page
    end
  end
end
