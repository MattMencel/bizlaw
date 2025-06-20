require "rails_helper"

RSpec.describe CasesController, type: :controller do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:case_record) { create(:case, course: course) }

  before do
    sign_in user
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe "navigation action methods" do
    describe "GET #background" do
      context "when accessing collection route" do
        it "returns a successful response" do
          get :background
          expect(response).to be_successful
        end

        it "assigns accessible cases" do
          accessible_case = create(:case)
          allow(Case).to receive(:accessible_by).with(user).and_return(Case.where(id: accessible_case.id))

          get :background
          expect(assigns(:cases)).to include(accessible_case)
        end
      end

      context "when accessing member route" do
        it "returns a successful response" do
          get :background, params: {id: case_record.id}
          expect(response).to be_successful
        end

        it "assigns the requested case" do
          get :background, params: {id: case_record.id}
          expect(assigns(:case)).to eq(case_record)
        end
      end
    end

    describe "GET #timeline" do
      let!(:case_event) { create(:case_event, case: case_record) }

      context "when accessing collection route" do
        it "returns a successful response" do
          get :timeline
          expect(response).to be_successful
        end

        it "assigns accessible cases" do
          accessible_case = create(:case)
          allow(Case).to receive(:accessible_by).with(user).and_return(Case.where(id: accessible_case.id))

          get :timeline
          expect(assigns(:cases)).to include(accessible_case)
        end
      end

      context "when accessing member route" do
        it "returns a successful response" do
          get :timeline, params: {id: case_record.id}
          expect(response).to be_successful
        end

        it "assigns the requested case and events" do
          get :timeline, params: {id: case_record.id}
          expect(assigns(:case)).to eq(case_record)
          expect(assigns(:events)).to include(case_event)
        end

        it "orders events by creation time" do
          older_event = create(:case_event, case: case_record, created_at: 1.day.ago)
          newer_event = create(:case_event, case: case_record, created_at: 1.hour.ago)

          get :timeline, params: {id: case_record.id}

          expect(assigns(:events).first).to eq(older_event)
          expect(assigns(:events).last).to eq(newer_event)
        end
      end
    end

    describe "GET #events" do
      let!(:case_event) { create(:case_event, case: case_record) }

      context "when accessing collection route" do
        it "returns a successful response" do
          get :events
          expect(response).to be_successful
        end
      end

      context "when accessing member route" do
        it "returns a successful response" do
          get :events, params: {id: case_record.id}
          expect(response).to be_successful
        end

        it "assigns the requested case and events" do
          get :events, params: {id: case_record.id}
          expect(assigns(:case)).to eq(case_record)
          expect(assigns(:events)).to include(case_event)
        end
      end
    end
  end

  describe "authorization" do
    context "when user lacks access to case" do
      before do
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it "raises authorization error for background action" do
        expect {
          get :background, params: {id: case_record.id}
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "raises authorization error for timeline action" do
        expect {
          get :timeline, params: {id: case_record.id}
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "raises authorization error for events action" do
        expect {
          get :events, params: {id: case_record.id}
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "route accessibility" do
    it "routes to background collection action" do
      expect(get: "/cases/background").to route_to(
        controller: "cases",
        action: "background"
      )
    end

    it "routes to timeline collection action" do
      expect(get: "/cases/timeline").to route_to(
        controller: "cases",
        action: "timeline"
      )
    end

    it "routes to events collection action" do
      expect(get: "/cases/events").to route_to(
        controller: "cases",
        action: "events"
      )
    end
  end
end
