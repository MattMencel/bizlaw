# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Negotiations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student1) { create(:user, :student, organization: organization) }
  let(:student2) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }

  # Create case with simulation
  let(:case_instance) { create(:case, :with_simulation, course: course, created_by: instructor) }
  let(:simulation) { case_instance.simulation }

  # Create teams (enrollments will be created automatically by factory)
  let(:plaintiff_team) { create(:team, course: course, owner: student1) }
  let(:defendant_team) { create(:team, course: course, owner: student2) }

  # Create case team assignments
  let!(:plaintiff_case_team) { create(:case_team, case: case_instance, team: plaintiff_team, role: "plaintiff") }
  let!(:defendant_case_team) { create(:case_team, case: case_instance, team: defendant_team, role: "defendant") }

  # Create team memberships
  let!(:plaintiff_member) { create(:team_member, team: plaintiff_team, user: student1, role: "member") }
  let!(:defendant_member) { create(:team_member, team: defendant_team, user: student2, role: "member") }

  # Create negotiation round
  let!(:negotiation_round) { create(:negotiation_round, :active, simulation: simulation, round_number: 1) }

  before do
    # Set simulation status to active
    simulation.update!(status: :active)
  end

  describe "GET /cases/:case_id/negotiations" do
    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get case_negotiations_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "displays negotiation rounds" do
        get case_negotiations_path(case_instance)
        expect(response.body).to include("Round 1")
      end

      it "loads simulation data" do
        get case_negotiations_path(case_instance)
        expect(response.body).to include("Negotiation")
        expect(response.body).to include("Round")
      end

      it "loads team-specific data" do
        get case_negotiations_path(case_instance)
        expect(response.body).to include(case_instance.title)
      end
    end

    context "when user is not on a team" do
      let(:unassigned_student) { create(:user, :student, organization: organization) }
      let!(:unassigned_enrollment) { create(:course_enrollment, user: unassigned_student, course: course) }

      before do
        sign_in unassigned_student
      end

      it "redirects with error message" do
        get case_negotiations_path(case_instance)
        expect(response).to redirect_to(cases_path)
        expect(flash[:alert]).to include("not assigned to a team")
      end
    end

    context "when case has no simulation" do
      let(:case_without_simulation) { create(:case, course: course, created_by: instructor) }

      before { sign_in student1 }

      it "redirects with error message" do
        get case_negotiations_path(case_without_simulation)
        expect(response).to redirect_to(cases_path)
        expect(flash[:alert]).to include("does not have an active simulation")
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get case_negotiations_path(case_instance)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/:id" do
    let!(:settlement_offer) { create(:settlement_offer, negotiation_round: negotiation_round, team: plaintiff_team, submitted_by: student1) }

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get case_negotiation_path(case_instance, negotiation_round)
        expect(response).to have_http_status(:success)
      end

      it "displays round details" do
        get case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:negotiation_round)).to eq(negotiation_round)
        expect(assigns(:team_offer)).to eq(settlement_offer)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get case_negotiation_path(case_instance, negotiation_round)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/:id/submit_offer" do
    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get submit_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(response).to have_http_status(:success)
      end

      it "builds new settlement offer" do
        get submit_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:settlement_offer)).to be_a_new(SettlementOffer)
        expect(assigns(:settlement_offer).team).to eq(plaintiff_team)
        expect(assigns(:settlement_offer).submitted_by).to eq(student1)
      end

      it "loads argument templates" do
        get submit_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:argument_templates)).to have_key(:legal_precedent)
        expect(assigns(:argument_templates)).to have_key(:economic_damages)
      end

      it "loads non-monetary options" do
        get submit_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:non_monetary_options)).to have_key(:confidentiality)
        expect(assigns(:non_monetary_options)).to have_key(:admissions)
      end
    end
  end

  describe "POST /cases/:case_id/negotiations/:id/create_offer" do
    let(:valid_offer_params) do
      {
        settlement_offer: {
          amount: 250000,
          justification: "Comprehensive settlement reflecting significant damages and impact on client's career and well-being.",
          non_monetary_terms: "Confidentiality agreement, policy updates, and training implementation",
          offer_type: "initial_demand"
        }
      }
    end

    let(:invalid_offer_params) do
      {
        settlement_offer: {
          amount: nil,
          justification: "",
          offer_type: "initial_demand"
        }
      }
    end

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      context "with valid parameters" do
        it "creates settlement offer" do
          # Mock the API call to avoid HTTP requests in tests
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(true)

          expect {
            post create_offer_case_negotiation_path(case_instance, negotiation_round), params: valid_offer_params
          }.to change(SettlementOffer, :count).by(1)
        end

        it "redirects to negotiations index with success notice" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(true)

          post create_offer_case_negotiation_path(case_instance, negotiation_round), params: valid_offer_params

          expect(response).to redirect_to(case_negotiations_path(case_instance))
          expect(flash[:notice]).to include("submitted successfully")
        end
      end

      context "with invalid parameters" do
        it "does not create settlement offer" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(false)

          expect {
            post create_offer_case_negotiation_path(case_instance, negotiation_round), params: invalid_offer_params
          }.not_to change(SettlementOffer, :count)
        end

        it "renders submit_offer template with errors" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(false)

          post create_offer_case_negotiation_path(case_instance, negotiation_round), params: invalid_offer_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:submit_offer)
          expect(flash.now[:alert]).to include("correct the errors")
        end
      end

      context "when consulting client" do
        it "redirects to client consultation" do
          post create_offer_case_negotiation_path(case_instance, negotiation_round),
            params: valid_offer_params.merge(consult_client: "1")

          expect(response).to redirect_to(client_consultation_case_negotiation_path(case_instance, negotiation_round))
        end
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/:id/counter_offer" do
    let!(:opposing_offer) { create(:settlement_offer, negotiation_round: negotiation_round, team: defendant_team, submitted_by: student2) }

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get counter_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(response).to have_http_status(:success)
      end

      it "loads original offer" do
        get counter_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:original_offer)).to eq(opposing_offer)
      end

      it "builds counter offer response" do
        get counter_offer_case_negotiation_path(case_instance, negotiation_round)
        settlement_offer = assigns(:settlement_offer)
        expect(settlement_offer).to be_a_new(SettlementOffer)
        expect(settlement_offer.offer_type).to eq("counteroffer")
      end
    end

    context "when no opposing offer exists" do
      before { sign_in student1 }

      it "redirects with error message" do
        get counter_offer_case_negotiation_path(case_instance, negotiation_round)
        expect(response).to redirect_to(case_negotiations_path(case_instance))
        expect(flash[:alert]).to include("No opposing offer found")
      end
    end
  end

  describe "POST /cases/:case_id/negotiations/:id/submit_counter_offer" do
    let!(:opposing_offer) { create(:settlement_offer, negotiation_round: negotiation_round, team: defendant_team, submitted_by: student2) }

    let(:counter_offer_params) do
      {
        settlement_offer: {
          amount: 200000,
          justification: "Counter-offer considering defendant's position while maintaining fair compensation for damages.",
          non_monetary_terms: "Modified confidentiality terms and training requirements",
          offer_type: "counteroffer"
        }
      }
    end

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      context "with successful API submission" do
        it "redirects with success notice" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(true)

          post submit_counter_offer_case_negotiation_path(case_instance, negotiation_round), params: counter_offer_params

          expect(response).to redirect_to(case_negotiations_path(case_instance))
          expect(flash[:notice]).to include("Counter-offer submitted successfully")
        end
      end

      context "with failed API submission" do
        it "renders counter_offer template with errors" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(false)

          post submit_counter_offer_case_negotiation_path(case_instance, negotiation_round), params: counter_offer_params

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:counter_offer)
        end
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/:id/client_consultation" do
    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)
        expect(response).to have_http_status(:success)
      end

      it "loads client consultation data" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)
        expect(assigns(:client_data)).to have_key(:priorities)
        expect(assigns(:client_data)).to have_key(:concerns)
        expect(assigns(:client_data)).to have_key(:acceptable_range)
      end

      it "loads different data for plaintiff vs defendant team" do
        # Test as plaintiff team member
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)
        plaintiff_priorities = assigns(:client_data)[:priorities]

        sign_in student2 # Switch to defendant team member
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)
        defendant_priorities = assigns(:client_data)[:priorities]

        expect(plaintiff_priorities).not_to eq(defendant_priorities)
      end
    end
  end

  describe "POST /cases/:case_id/negotiations/:id/consult_client" do
    let(:consultation_params) do
      {
        settlement_offer: {
          amount: 250000,
          justification: "Client consultation offer",
          offer_type: "initial_demand"
        }
      }
    end

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      context "when proceeding with offer" do
        it "submits offer and redirects" do
          allow_any_instance_of(NegotiationsController).to receive(:submit_offer_via_api).and_return(true)

          post consult_client_case_negotiation_path(case_instance, negotiation_round),
            params: consultation_params.merge(proceed_with_offer: "1")

          expect(response).to redirect_to(case_negotiations_path(case_instance))
          expect(flash[:notice]).to include("submitted after client consultation")
        end
      end

      context "when not proceeding with offer" do
        it "redirects to submit offer page" do
          post consult_client_case_negotiation_path(case_instance, negotiation_round), params: consultation_params

          expect(response).to redirect_to(submit_offer_case_negotiation_path(case_instance, negotiation_round))
          expect(flash[:notice]).to include("consultation completed")
        end
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/history" do
    let!(:completed_round) { create(:negotiation_round, :completed, simulation: simulation, round_number: 2) }
    let!(:plaintiff_offer) { create(:settlement_offer, :plaintiff_offer, negotiation_round: completed_round, team: plaintiff_team) }
    let!(:defendant_offer) { create(:settlement_offer, :defendant_offer, negotiation_round: completed_round, team: defendant_team) }

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get history_case_negotiations_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "loads all negotiation rounds" do
        get history_case_negotiations_path(case_instance)
        expect(assigns(:all_rounds)).to include(negotiation_round, completed_round)
      end

      it "builds negotiation timeline" do
        get history_case_negotiations_path(case_instance)
        timeline = assigns(:negotiation_timeline)
        expect(timeline).to be_an(Array)
        expect(timeline.length).to be >= 2 # At least plaintiff and defendant offers
      end

      it "analyzes settlement progress" do
        get history_case_negotiations_path(case_instance)
        analysis = assigns(:settlement_analysis)
        expect(analysis).to include(:current_gap) if analysis.any?
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/templates" do
    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get templates_case_negotiations_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "loads argument templates" do
        get templates_case_negotiations_path(case_instance)
        templates = assigns(:templates)
        expect(templates).to have_key(:legal_precedent)
        expect(templates).to have_key(:economic_damages)
        expect(templates).to have_key(:risk_assessment)
        expect(templates).to have_key(:client_impact)
      end

      context "with XHR request" do
        it "returns JSON response" do
          get templates_case_negotiations_path(case_instance), xhr: true
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")
        end
      end
    end
  end

  describe "GET /cases/:case_id/negotiations/calculator" do
    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      it "returns successful response" do
        get calculator_case_negotiations_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "loads damage calculation categories" do
        get calculator_case_negotiations_path(case_instance)
        categories = assigns(:damage_categories)
        expect(categories).to be_an(Array)
        expect(categories.first).to have_key(:category)
      end

      it "loads case-specific calculation data" do
        get calculator_case_negotiations_path(case_instance)
        case_data = assigns(:case_specific_data)
        expect(case_data).to have_key(:plaintiff_salary)
      end
    end

    context "with POST request" do
      let(:calculation_params) do
        {
          calculation: {
            monthly_salary: 7000,
            unemployment_months: 8,
            therapy_sessions: 24
          }
        }
      end

      before { sign_in student1 }

      it "performs damage calculation" do
        post calculator_case_negotiations_path(case_instance), params: calculation_params
        expect(response).to have_http_status(:success)
        expect(assigns(:calculation_results)).to eq(calculation_params[:calculation])
      end

      context "with XHR request" do
        it "returns JSON response" do
          post calculator_case_negotiations_path(case_instance), params: calculation_params, xhr: true
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")
        end
      end
    end
  end

  describe "private methods" do
    before { sign_in student1 }

    describe "#set_case" do
      context "when case exists" do
        it "sets @case instance variable" do
          get case_negotiations_path(case_instance)
          expect(assigns(:case)).to eq(case_instance)
        end
      end

      context "when case does not exist" do
        it "redirects with error message" do
          get "/cases/99999/negotiations"
          expect(response).to redirect_to(cases_path)
          expect(flash[:alert]).to include("not found")
        end
      end
    end

    describe "#set_simulation" do
      it "sets @simulation from case" do
        get case_negotiations_path(case_instance)
        expect(assigns(:simulation)).to eq(simulation)
      end
    end

    describe "#verify_team_participation" do
      it "allows team members to access" do
        get case_negotiations_path(case_instance)
        expect(response).to have_http_status(:success)
      end
    end

    describe "#current_user_team" do
      it "returns the user's team for the case" do
        get case_negotiations_path(case_instance)
        # This tests that the controller method works correctly
        # The team assignment is verified by successful page access
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "client consultation logic" do
    before { sign_in student1 }

    context "for plaintiff team" do
      it "provides plaintiff-specific priorities" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)

        priorities = assigns(:client_data)[:priorities]
        expect(priorities.any? { |p| p[:name].include?("Financial Security") }).to be true
        expect(priorities.any? { |p| p[:name].include?("Justice") }).to be true
      end

      it "provides appropriate acceptable range" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)

        range = assigns(:client_data)[:acceptable_range]
        expect(range[:minimum]).to eq(simulation.plaintiff_min_acceptable)
        expect(range[:ideal]).to eq(simulation.plaintiff_ideal)
      end
    end

    context "for defendant team" do
      before { sign_in student2 }

      it "provides defendant-specific priorities" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)

        priorities = assigns(:client_data)[:priorities]
        expect(priorities.any? { |p| p[:name].include?("Cost Minimization") }).to be true
        expect(priorities.any? { |p| p[:name].include?("Reputation") }).to be true
      end

      it "provides appropriate acceptable range" do
        get client_consultation_case_negotiation_path(case_instance, negotiation_round)

        range = assigns(:client_data)[:acceptable_range]
        expect(range[:ideal]).to eq(simulation.defendant_ideal)
        expect(range[:maximum]).to eq(simulation.defendant_max_acceptable)
      end
    end
  end

  describe "pressure and mood calculations" do
    before { sign_in student1 }

    it "calculates timeline pressure correctly" do
      # Test different pressure levels based on rounds remaining
      simulation.update!(current_round: 5, total_rounds: 6) # Should be "Critical"

      get case_negotiations_path(case_instance)
      pressure_status = assigns(:pressure_status)

      expect(pressure_status[:timeline_pressure]).to eq("Critical")
      expect(pressure_status[:current_round]).to eq(5)
      expect(pressure_status[:total_rounds]).to eq(6)
    end

    it "provides client mood data" do
      get case_negotiations_path(case_instance)
      client_mood = assigns(:client_mood)

      expect(client_mood).to have_key(:mood)
      expect(client_mood).to have_key(:confidence)
      expect(client_mood).to have_key(:satisfaction)
      expect(client_mood).to have_key(:pressure_level)
    end
  end

  describe "POST /cases/:case_id/negotiations/:id/ai_client_reaction" do
    let(:ai_reaction_params) do
      {
        amount: 150000,
        justification: "Fair settlement considering damages",
        non_monetary_terms: "Confidentiality agreement"
      }
    end

    context "when user is authenticated and on a team" do
      before { sign_in student1 }

      context "with valid parameters" do
        it "returns successful JSON response" do
          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")
        end

        it "returns AI-generated reaction when AI service is enabled" do
          # Mock AI service as enabled and returning data
          ai_service_mock = instance_double(GoogleAiService)
          allow(GoogleAiService).to receive(:new).and_return(ai_service_mock)
          allow(ai_service_mock).to receive(:enabled?).and_return(true)
          allow(ai_service_mock).to receive(:generate_settlement_feedback).and_return({
            mood_level: "satisfied",
            feedback_text: "This settlement amount is acceptable to your client.",
            satisfaction_score: 85,
            strategic_guidance: "Consider including additional non-monetary terms.",
            cost: 0.05,
            response_time: 1.2
          })

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("reaction")
          expect(json_response["reaction"]["source"]).to eq("ai")
          expect(json_response["reaction"]["reaction"]).to eq("pleased")
          expect(json_response["reaction"]["message"]).to include("acceptable")
        end

        it "returns fallback reaction when AI service is disabled" do
          # Mock AI service as disabled
          ai_service_mock = instance_double(GoogleAiService)
          allow(GoogleAiService).to receive(:new).and_return(ai_service_mock)
          allow(ai_service_mock).to receive(:enabled?).and_return(false)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("reaction")
          expect(json_response["reaction"]["source"]).to eq("fallback")
        end

        it "generates appropriate reaction based on settlement amount for plaintiff team" do
          # Test with amount above ideal threshold
          high_amount_params = ai_reaction_params.merge(amount: 300000)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: high_amount_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response["reaction"]["reaction"]).to eq("pleased")
        end

        it "generates appropriate reaction based on settlement amount for defendant team" do
          sign_in student2 # Switch to defendant team

          # Test with low amount (good for defendant)
          low_amount_params = ai_reaction_params.merge(amount: 50000)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: low_amount_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response["reaction"]["reaction"]).to eq("pleased")
        end
      end

      context "with invalid parameters" do
        it "returns error for missing amount" do
          invalid_params = ai_reaction_params.except(:amount)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: invalid_params,
            headers: {"Accept" => "application/json"}

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("error")
          expect(json_response["error"]).to include("Invalid settlement amount")
        end

        it "returns error for zero amount" do
          invalid_params = ai_reaction_params.merge(amount: 0)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: invalid_params,
            headers: {"Accept" => "application/json"}

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("error")
          expect(json_response["fallback"]).to have_key("reaction")
        end

        it "returns error for negative amount" do
          invalid_params = ai_reaction_params.merge(amount: -1000)

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: invalid_params,
            headers: {"Accept" => "application/json"}

          expect(response).to have_http_status(:bad_request)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("error")
        end
      end

      context "when AI service raises an error" do
        it "falls back to rule-based reaction" do
          # Mock AI service to raise an error
          ai_service_mock = instance_double(GoogleAiService)
          allow(GoogleAiService).to receive(:new).and_return(ai_service_mock)
          allow(ai_service_mock).to receive(:enabled?).and_return(true)
          allow(ai_service_mock).to receive(:generate_settlement_feedback).and_raise(StandardError, "AI service error")

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          expect(response).to have_http_status(:internal_server_error)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("error")
          expect(json_response).to have_key("fallback")
          expect(json_response["fallback"]).to have_key("reaction")
        end
      end

      context "mood mapping functionality" do
        it "correctly maps AI mood levels to reaction types" do
          ai_service_mock = instance_double(GoogleAiService)
          allow(GoogleAiService).to receive(:new).and_return(ai_service_mock)
          allow(ai_service_mock).to receive(:enabled?).and_return(true)

          # Test very satisfied -> pleased mapping
          allow(ai_service_mock).to receive(:generate_settlement_feedback).and_return({
            mood_level: "very_satisfied",
            feedback_text: "Excellent settlement",
            satisfaction_score: 95
          })

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response["reaction"]["reaction"]).to eq("pleased")

          # Test unhappy -> concerned mapping
          allow(ai_service_mock).to receive(:generate_settlement_feedback).and_return({
            mood_level: "unhappy",
            feedback_text: "Settlement too low",
            satisfaction_score: 30
          })

          post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
            params: ai_reaction_params,
            headers: {"Accept" => "application/json"}

          json_response = JSON.parse(response.body)
          expect(json_response["reaction"]["reaction"]).to eq("concerned")
        end
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
          params: ai_reaction_params

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not on a team" do
      let(:unassigned_student) { create(:user, :student, organization: organization) }
      let!(:unassigned_enrollment) { create(:course_enrollment, user: unassigned_student, course: course) }

      before { sign_in unassigned_student }

      it "redirects with error message" do
        post ai_client_reaction_case_negotiation_path(case_instance, negotiation_round),
          params: ai_reaction_params

        expect(response).to redirect_to(cases_path)
        expect(flash[:alert]).to include("not assigned to a team")
      end
    end
  end
end
