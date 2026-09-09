# frozen_string_literal: true

module Demo
  # The development run. Without a second live player there is no other way to
  # develop the game view at all, so this is scaffolding that stays: `rake
  # demo:seed` lays down the playable Day 3 and the Day 1 cold open, and it is
  # re-run constantly, where a no-op would be useless once the Day has been
  # played.
  #
  # Every act goes through the real seams in the Day's own order — `Days::
  # Command` for each spend, `Offers::Stage` then the commit, `Days::Commit`
  # for each close. A seed that wrote rows directly to dodge the ordering would
  # stop being evidence the engine works.
  #
  # What it lays down is settled by #332: the player takes the plaintiff, alone
  # on his Side, and sits down on Day 3 opposite a defendant who has already
  # played its whole morning. See #336 for the acts and why each is forced.
  class Seed
    # The one identifier the reset is guarded to. Nothing outside the
    # Organization by this name is ever reachable from here.
    ORGANIZATION = "Demo College"
    SECTION = "Business Law 355, Fall 2026"

    REFERENCE_IDENTIFIER = "bizlaw/reference"
    REFERENCE_PATH = "db/cases/reference.yml"

    # The Day the player sits down on. Forced rather than preferred:
    # `depose_witness` carries a lead time of two Days, so Day 3 is the earliest
    # a served Exhibit can exist, and `MorningBriefing#served` filters on the
    # Case File row's own ordinal, so a Day 3 service falls out of a narrower
    # Day 4 briefing entirely.
    DEMO_DAY = 3

    # The stable identifiers, and they are not primary keys. A reserved id
    # cannot be held: SQLite allocates from `MAX(sequence, the largest rowid
    # present) + 1`, so the demo's own rows push the counter past the range it
    # was trying to keep, and the next ordinary Simulation lands inside it. What
    # is stable instead is the run's own name, resolved against the one
    # Organization this seed owns — which is the name the reset is already
    # guarded to, so there is one well-known identifier rather than three.
    DEMO = "day-3"
    COLD_OPEN = "cold-open"

    Result = Data.define(:demo, :cold_open)

    # The tables a Simulation's run writes, children before parents. Every
    # association in the run is `dependent: :restrict_with_error` — deletion is
    # Retention's business rather than a cascade — so the reset says the order
    # out loud rather than asking Rails to work it out.
    RUN_TABLES = [
      PlayedExhibit, StagedOfferExhibit, OfferAcceptance, CommittedOffer,
      StagedOffer, ClientShift, SecondWaiver, DayCommitment, DocketEntry,
      CaseFileDocument, DayBudget, Day, Side, Simulation
    ].freeze

    def self.call(...) = new(...).call

    # The one place a screen asks which Simulation a demo URL names, so the
    # answer is not spelled out again in a controller. The two runs are told
    # apart by the order they were laid down in, which is the order this seed
    # lays them down in and the only thing about them that is not identical:
    # they share a Section and a Case Version, which is the point of the pair.
    #
    # Order alone would answer a third Simulation under this Organization to
    # one of the two names, and answer it wrongly. The seed owns the whole
    # Organization — the reset destroys everything under it on every run — so a
    # third run there is an anomaly rather than something to choose between,
    # and it is refused rather than resolved.
    def self.simulation(run)
      laid = Simulation.joins(section: :organization)
        .where(organizations: {name: ORGANIZATION}).order(:id).to_a
      unless laid.size == 2
        raise "#{ORGANIZATION} holds #{laid.size} Simulations, and the demo is a pair — " \
              "re-run `rake demo:seed`"
      end

      case run.to_s
      when DEMO then laid.first
      when COLD_OPEN then laid.last
      else raise ArgumentError, "#{run.inspect} is not a demo run"
      end
    end

    def initialize(base_url: "http://localhost:3000")
      @base_url = base_url
    end

    def call
      reset
      organization = Organization.create!(name: ORGANIZATION)
      section = organization.sections.create!(name: SECTION)

      Result.new(demo: demo_run(section), cold_open: cold_open(section))
    end

    # Where the player and the professor are sent. There is no route yet — the
    # view is what this seed exists to build — so this is the URL shape the
    # screens will serve, printed so it is one copy rather than one guess.
    #
    # It names the run rather than its id, which is the whole of why the URL a
    # run prints is the URL the next reset prints: the rows underneath are new
    # every time, and nothing in the address depends on them.
    def url_for(run) = "#{base_url}/demo/#{run}"

    private

    attr_reader :base_url

    # The demo run, played forward through Days 1–3. The plaintiff's Day 3 is
    # deliberately untouched: it is the Day the player is handed.
    def demo_run(section)
      simulation = lay_out(section)
      day_one(simulation)
      day_two(simulation)
      the_defendant_moves_first(simulation)
      simulation
    end

    # Day 1 open, nothing spent, and the claim under test is that the empty
    # state is the tutorial — so anything on this Docket is the answer leaking.
    # It shares the Section with the demo run, which is the exact case the
    # `(parent_id, simulation_id, organization_id)` keys exist for.
    def cold_open(section)
      lay_out(section)
    end

    def lay_out(section)
      Simulations::Create.call(section: section, case_version: case_version)
    end

    # Defendant deposes the plant supervisor, which lands on Day 3 and is the
    # ammunition it plays at him. Plaintiff opens his own discovery: the
    # personnel file and the precedent memo, both landing on Day 2.
    #
    # No Consult on Days 1–2. It reads `firm` today and it will read `firm` on
    # Day 3, and spending the one live beat twice makes the Action look duller
    # than it is.
    def day_one(simulation)
      day = simulation.days.find_by!(ordinal: 1)
      spend(simulation.defendant_side, day, CaseAction::DEPOSE_WITNESS, by: defendant_lead)
      spend(simulation.plaintiff_side, day, CaseAction::REQUEST_DOCUMENTS, by: player)
      spend(simulation.plaintiff_side, day, CaseAction::RESEARCH_PRECEDENT, by: player)
      close(day, simulation)
    end

    # The press statement, bought to land on the demo morning. Without it the
    # briefing's landed section is empty on the one Day anybody looks at it.
    def day_two(simulation)
      day = simulation.days.find_by!(ordinal: 2)
      spend(simulation.plaintiff_side, day, CaseAction::MANAGE_PRESS, by: player)
      close(day, simulation)
    end

    # The fiction is that the other firm moved first thing in the morning,
    # which is what an asynchronous calendar looks like anyway. The deposition
    # landed as Day 3 opened; the defendant stages a position over it, seconds
    # it between two real members rather than under a waiver, and commits at one
    # point for the Offer plus the Case's Exhibit price — the pool exactly.
    #
    # Service moves the plaintiff's Client, and the commit implies the
    # defendant's own `DayCommitment`, so the player's is the second and closes
    # the Day.
    def the_defendant_moves_first(simulation)
      side = simulation.defendant_side
      day = simulation.days.find_by!(ordinal: DEMO_DAY)

      Offers::Stage.call(
        side: side,
        day: day,
        by: defendant_lead,
        # `money` is what the deposition bears on, which is what makes service
        # move the plaintiff's Client rather than merely inform him.
        terms: {"money" => 40_000_00, "nda" => nil},
        exhibits: [held(side, "deposition_of_the_supervisor")],
        note: "Without prejudice. Open for acceptance today."
      )

      Days::Command.apply(
        act: :commit_offer, side: side, day: day,
        by: defendant_lead, seconded_by: defendant_second
      )
    end

    def spend(side, day, kind, by:)
      Days::Command.apply(act: :spend, side: side, day: day, by: by, kind: kind)
    end

    # Both Sides file, on every Day the seed closes: a Day closes on the second
    # commitment, so seeding only the defendant's would leave Days 1 and 2 open
    # underneath the player.
    #
    # Who files for the defendant is not decoration. There is no roster, so the
    # second member of that Side exists only once Attribution has seen them act
    # — and a teammate who has never acted cannot second the Day 3 commit. Their
    # act is filing Day 2.
    def close(day, simulation)
      Days::Commit.call(side: simulation.plaintiff_side, day: day, by: player)
      filed_by = (day.ordinal == 2) ? defendant_second : defendant_lead
      Days::Commit.call(side: simulation.defendant_side, day: day, by: filed_by)
    end

    def held(side, identifier)
      side.case_file_documents.joins(:case_document)
        .find_by!(case_documents: {identifier: identifier})
    end

    # The player, alone on his Side for two Days. `Side#members` folds from
    # Attribution alone, so every plaintiff act is attributed to him: a phantom
    # teammate would make the Side two members, `seconders_other_than` would
    # return one, and the dead countersignature block the Docket teaches by —
    # along with the waiver that revives it — would both evaporate.
    def player
      @player ||= member("Sam Ortega", "player@example.edu")
    end

    def defendant_lead = @defendant_lead ||= member("Dana Whitfield", "dana@example.edu")

    def defendant_second = @defendant_second ||= member("Ray Okonkwo", "ray@example.edu")

    def member(name, email)
      User.create_or_find_by!(organization: organization, email: email) do |user|
        user.name = name
      end
    end

    def organization = @organization ||= Organization.find_by!(name: ORGANIZATION)

    # The latest published Version of the engine's own reference Case, imported
    # if this database has never seen it.
    def case_version
      @case_version ||= published_reference || import_the_reference_case
    end

    def published_reference
      CaseVersion.joins(:case)
        .where.not(published_at: nil)
        .where(cases: {identifier: REFERENCE_IDENTIFIER})
        .order(:id).last
    end

    def import_the_reference_case = Cases::Import.call(Rails.root.join(REFERENCE_PATH))

    # Destroys the demo Organization and everything under it, and nothing else:
    # every statement below is scoped to the one Organization found by the
    # well-known name, so a run against a database holding real work cannot
    # reach it.
    def reset
      existing = Organization.find_by(name: ORGANIZATION)
      return if existing.nil?

      ActiveRecord::Base.transaction do
        offer_terms_under(existing)
        RUN_TABLES.each { |model| model.where(organization_id: existing.id).delete_all }
        User.where(organization_id: existing.id).delete_all
        Section.where(organization_id: existing.id).delete_all
        existing.delete
      end
    end

    # The two term tables carry no `organization_id` — a Term belongs to the
    # Offer it is written on — so they are deleted through their parents.
    def offer_terms_under(existing)
      {StagedOfferTerm => StagedOffer, CommittedOfferTerm => CommittedOffer}.each do |terms, offers|
        terms.where(
          offers.table_name.singularize => offers.where(organization_id: existing.id)
        ).delete_all
      end
    end
  end
end
