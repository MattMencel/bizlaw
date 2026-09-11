# frozen_string_literal: true

module Demo
  # Who is reading, and which Side they are reading as.
  #
  # Every seam in the Day takes a `by:` — `Days::Command`, `Offers::Stage`,
  # `Offers::Accept`, `Days::Commit`, `Offers::WaiveSecond` — and there is no
  # authentication, no session and no `Current.user` in this app. This is what
  # answers it, and it answers from the seed's own cast rather than from the
  # database's shape.
  #
  # It is deliberately not Attribution. `Side#members` folds from the ledgers,
  # which answers *who is on this Team* — the roster — and the two questions
  # only coincide while the seed guarantees one member. They come apart at the
  # cold open, where nobody has acted and the fold has no one to name, which is
  # precisely the Day the first act has to be attributed on.
  #
  # Nothing here writes. Resolving a seat cannot make anyone a member of
  # anything, which is what keeps the map's "one attributed plaintiff, forever"
  # true however many tabs are open.
  #
  # This is demo scaffolding and it is namespaced as such. When there is
  # authentication, it is replaced rather than grown into.
  class Seat
    UnknownSeat = Class.new(ArgumentError)

    # The Instructor's segment. The two Sides are addressed by their role, which
    # is the name the URL already wants and one this cannot get out of step
    # with; the Instructor has no role because they are not in the dispute.
    INSTRUCTOR = "instructor"

    # Segment to the email the seed knows that person by. A person, not a name:
    # the cast is cast, and renaming Dana Whitfield should not break a URL in an
    # open tab.
    SEGMENTS = {
      Side::PLAINTIFF => Seed::PLAYER_EMAIL,
      Side::DEFENDANT => Seed::DEFENDANT_LEAD_EMAIL,
      INSTRUCTOR => Seed::INSTRUCTOR_EMAIL
    }.freeze

    # The bare `/demo/:run` is the player's, because #332 settled that the
    # player is the plaintiff and the URL `rake demo:seed` prints names a run
    # and nothing else. The named form resolves identically rather than being a
    # second path to the same place.
    DEFAULT = Side::PLAINTIFF

    def self.for(simulation, segment = nil) = new(simulation, segment).resolve

    def initialize(simulation, segment = nil)
      @simulation = simulation
      @segment = (segment.presence || DEFAULT).to_s
    end

    def resolve
      email = SEGMENTS[segment]
      raise UnknownSeat, "#{segment.inspect} is not a demo seat" if email.nil?

      Seated.new(segment: segment, user: user(email), side: side)
    end

    private

    attr_reader :simulation, :segment

    # The Side this seat sits on, and `nil` for the Instructor. The nil is the
    # fact rather than a gap: the Instructor is not a player, and the Side a
    # waiver is granted to is chosen per act rather than sat in.
    def side
      return nil if segment == INSTRUCTOR

      simulation.sides.find_by!(role: segment)
    end

    # Resolved against the Organization the seed owns outright, so a database
    # holding other work cannot answer here. A missing person is the seed not
    # having been run, which is the same fault `Seed.simulation` already names.
    def user(email)
      User.find_by(organization_id: simulation.organization_id, email: email) ||
        raise(UnknownSeat, "#{Seed::ORGANIZATION} seats nobody at #{email} — " \
                           "re-run `rake demo:seed`")
    end

    # The pair, plus the segment it was named by. Held as a value rather than
    # threaded through as two arguments, because every act downstream needs
    # both and a controller passing them separately is where they drift apart.
    Seated = Data.define(:segment, :user, :side) do
      # Whether this seat is in the dispute at all. Callers ask this rather
      # than testing the Side for nil, because the answer is about the person
      # and not about the column.
      def seated? = !side.nil?
    end
  end
end
