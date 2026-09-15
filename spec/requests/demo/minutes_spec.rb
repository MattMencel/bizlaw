# frozen_string_literal: true

require "rails_helper"

# The Instructor's address. What is under test is that it resolves them from the
# constant rather than from what the URL spelled, that the Day it acts on is the
# one being played, and that it is a different instrument from a Team's file
# rather than the same one read from another chair.
RSpec.describe "the Instructor's minute", type: :request do
  before { Demo::Seed.call }

  let(:simulation) { Demo::Seed.simulation(Demo::Seed::DEMO) }
  let(:instructor) { User.find_by!(email: Demo::Seed::INSTRUCTOR_EMAIL) }

  def visit_minute(run: Demo::Seed::DEMO)
    get "/demo/#{run}/#{Demo::Seat::INSTRUCTOR}"
  end

  it "renders the minute, not the working draft" do
    visit_minute

    expect(inertia.component).to eq("Demo/Minute")
  end

  # There is no authentication and no session, so the address is the whole of
  # what says who is reading — and for this page the route *is* the Instructor,
  # so there is nothing left for a parameter to say.
  it "seats the Instructor" do
    visit_minute

    expect(inertia.props[:letterhead][:you]).to eq(instructor.name)
  end

  # The Day is the sitting one and there is no picker: a waiver is granted for
  # the Day it is granted on, and reaching into a Day nobody is playing is not
  # among the powers `CONTEXT.md` § Instructor lists.
  it "opens on the Day being played" do
    visit_minute

    expect(inertia.props[:letterhead][:day]).to eq(Demo::Seed::DEMO_DAY)
  end

  it "opens the cold open on its own first Day" do
    visit_minute(run: Demo::Seed::COLD_OPEN)

    expect(inertia.props[:letterhead][:day]).to eq(1)
  end

  # The minute has no half, no term sheet, no Client and no Case File. A page
  # that grew a Team's papers would be the console #312 ruled out, arriving by
  # increment — so this binds the absence rather than trusting the markup.
  it "carries nothing of a Team's file" do
    visit_minute

    # `errors` is Inertia's own shared prop and is on every page it renders.
    expect(inertia.props.keys.map(&:to_s) - ["errors"])
      .to match_array(%w[letterhead settled lines waiver_path])
  end

  it "does not know a run it did not lay down" do
    visit_minute(run: "whatever")

    expect(response).to have_http_status(:not_found)
  end
end
