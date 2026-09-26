# frozen_string_literal: true

require "rails_helper"

# The whole of a settled run as one page. What is under test is the seam rather
# than `ExecutedInstrument` behind it: that a Day has become an ordinal and an
# in-fiction date, a User a name, a Term a label, money a string and a Client's
# seed and expression a rendered face — and that the two things this page is
# *not* allowed to print are absent.
RSpec.describe ExecutedFile do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:opponent) { simulation.defendant_side }
  let(:day) { simulation.days.first }
  let(:organization) { simulation.section.organization }
  let(:sam) { a_user(organization: organization) }
  let(:priya) do
    a_user(organization: organization, name: "Priya Raman", email: "priya@example.edu")
  end
  let(:ray) do
    a_user(organization: organization, name: "Ray Okonkwo", email: "ray@example.edu")
  end

  # The plaintiff draws and executes a position; the defendant takes it. Both
  # Sides need two attributed members before either gate can be satisfied, so
  # each teammate acts once before the act that needs them.
  def settle(seconded_by: priya)
    Days::Command.apply(act: :spend, side: side, day: day, by: priya,
      kind: CaseAction::CONSULT_CLIENT)
    Offers::Stage.call(side: side, day: day, by: sam, terms: {"money" => 90_000_00,
                                                              "apology" => nil})
    Days::Command.apply(act: :commit_offer, side: side, day: day, by: sam,
      seconded_by: seconded_by)

    Days::Command.apply(act: :spend, side: opponent, day: day, by: ray,
      kind: CaseAction::CONSULT_CLIENT)
    Offers::Accept.call(offer: side.committed_offer_on(day), side: opponent, day: day,
      by: priya, seconded_by: ray)
  end

  def props(of: side, you: sam) = described_class.for(of, you: you).to_props

  before { settle }

  describe "the letterhead" do
    it "names the matter, the Side and whoever is reading" do
      expect(props[:letterhead]).to include(
        matter: simulation.case_version.case.name,
        role: Side::PLAINTIFF,
        you: sam.name
      )
    end

    # The clock has stopped. An ordinal out of a calendar nobody will reach
    # again invites the reader to ask what happens tomorrow, which is the dead
    # end this page exists to not be.
    it "carries no Day and no calendar length" do
      expect(props[:letterhead].keys)
        .to contain_exactly(:matter, :title, :role, :role_label, :in_fiction_date, :you)
    end

    it "is dated by the Day the instrument was executed on" do
      expect(props[:letterhead][:in_fiction_date]).to eq(day.in_fiction_date.strftime("%B %-d, %Y"))
    end
  end

  describe "the terms" do
    it "prints the deal as it was fixed, formatted once" do
      expect(props[:terms]).to include(
        a_hash_including(term: "money", money: true, amount: "$90,000")
      )
    end

    # A settlement including an apology includes an apology.
    it "keeps a Term agreed without a figure" do
      expect(props[:terms]).to include(
        a_hash_including(term: "apology", money: false, amount: nil)
      )
    end

    # Authored beside the key, so the page never prints one made up from it.
    it "labels each Term as the Case authored it" do
      CaseTerm.find_by!(case_version: side.case_version, key: "apology")
        .update!(label: "A written apology")
      side.reload

      expect(props[:terms].pluck(:term, :label)).to include(["apology", "A written apology"])
    end

    # The whole of what separates this sheet from the working one. The redline
    # is gone because there is no position across the table any more, and the
    # margin is gone because the Client's aspiration beside the agreed figure
    # is a Settlement Quality read arriving through the layout.
    it "carries neither the other Side's position nor the Client's aspiration" do
      expect(props[:terms].flat_map(&:keys).uniq)
        .to contain_exactly(:term, :label, :money, :amount)
    end

    it "prints only the Terms that are on the instrument" do
      expect(props[:terms].pluck(:term)).to contain_exactly("money", "apology")
    end
  end

  describe "the signatures" do
    it "names both parties, drawer and seconder" do
      expect(props[:signatures]).to eq([
        {role: Side::PLAINTIFF, for: "For the Plaintiff", signed_by: sam.name,
         seconded_by: priya.name, waived: false},
        {role: Side::DEFENDANT, for: "For the Defendant", signed_by: priya.name,
         seconded_by: ray.name, waived: false}
      ])
    end

    it "puts the Side that drew the instrument first" do
      expect(props[:signatures].first[:role]).to eq(side.role)
    end

    # A waiver *substitutes* for the Second, so there is no seconder of record.
    # Saying so is the point: a blank second line on an executed instrument
    # would read as one nobody got round to.
    context "when the Offer was executed under an Instructor's waiver" do
      let(:instructor) do
        a_user(organization: organization, name: "Professor Adeyemi",
          email: "instructor@example.edu")
      end

      # Granted inside the act rather than in a `before`: RSpec runs the outer
      # hook first, so a waiver set up here would land after the commit it was
      # meant to release.
      def settle
        Offers::WaiveSecond.call(side: side, day: day, by: instructor)
        super(seconded_by: nil)
      end

      it "marks the line waived rather than leaving it blank" do
        expect(props[:signatures].first).to include(seconded_by: nil, waived: true)
      end
    end
  end

  describe "the execution stamp" do
    # Every other date on the instrument is the Case's calendar, and
    # `offer_acceptances.created_at` is the afternoon the demo happened to run.
    it "is dated in the fiction rather than by the wall clock" do
      written = day.in_fiction_date.strftime("%B %-d, %Y")

      expect(props[:stamp]).to eq(
        day: day.ordinal, in_fiction_date: written,
        caption: I18n.t("reads.executed_instrument.terms.caption", day: day.ordinal, date: written)
      )
    end
  end

  describe "the Client's beat" do
    # The plaintiff drew the instrument and the defendant took it, so it is the
    # plaintiff whose paper was accepted.
    it "carries the Client's own authored line" do
      expect(props[:beat][:line]).to eq(side.client.settlement_line(CaseClient::HAD_IT_TAKEN))
    end

    # "You took their number" and "they took ours" are different feelings about
    # identical terms, and the acceptance role is the one dimension the act
    # itself supplies.
    it "reads the other Side's line off the same instrument" do
      expect(props(of: opponent, you: priya)[:beat][:line])
        .to eq(opponent.client.settlement_line(CaseClient::TOOK_IT))
    end

    it "composes the face at the one size a Client is served at" do
      expect(props[:beat][:portrait]).to include(%(width="#{Typeset::PORTRAIT_SIZE}"))
    end

    # ADR 0007: *firm* and *ready* mean willing to keep holding out, which is
    # moot once the instrument is executed. A band here would be a free read on
    # how the deal landed.
    it "carries no Reaction Band" do
      expect(props[:beat].keys).to contain_exactly(:line, :portrait)
    end
  end

  describe "the back of the file" do
    it "still turns to the Case File and the Docket" do
      expect(props[:back].keys).to contain_exactly(:copy, :case_file, :docket)
    end

    # The Docket is a record of what *this* Team did, so the Acceptance appears
    # on the accepting Team's. The Side whose Offer was taken learns it from
    # this page, which is the whole of ADR 0007's point about there being no
    # Morning Briefing after a settlement.
    it "names the Acceptance on the accepting Team's Docket" do
      expect(props(of: opponent, you: priya)[:back][:docket][:entries].pluck(:act_label))
        .to include("Accepted their Offer")
    end

    # The bug #380 fixed on the commit, which this page renders too: executing
    # a draft is a spend with no authored Action to take a name from, so asking
    # I18n for `kinds.` resolves to the whole Hash and prints as `[object
    # Object]`.
    it "names executing the draft rather than printing a Hash" do
      committed = props[:back][:docket][:entries]
        .find { |entry| entry[:spend] && entry[:kind].nil? }

      expect(committed[:act_label]).to eq(I18n.t("reads.docket.acts.offer_committed"))
    end
  end

  it "hands the page nothing it has to compute" do
    expect(props.keys).to contain_exactly(
      :copy, :letterhead, :terms, :signatures, :stamp, :beat, :back
    )
  end
end
