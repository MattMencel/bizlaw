# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Simulations", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_instance) { create(:case, course: course, created_by: instructor) }

  # Create teams for simulation
  let(:plaintiff_team) { create(:team, course: course) }
  let(:defendant_team) { create(:team, course: course) }

  describe "GET /courses/:course_id/cases/:case_id/simulation/new" do
    context "when user is instructor" do
      before do
        sign_in instructor
        plaintiff_team # Force creation of teams
        defendant_team
      end

      it "returns success" do
        get new_course_case_simulation_path(course, case_instance)
        expect(response).to have_http_status(:success)
      end

      it "assigns a new simulation" do
        get new_course_case_simulation_path(course, case_instance)
        expect(assigns(:simulation)).to be_a_new(Simulation)
        expect(assigns(:simulation).case).to eq(case_instance)
      end

      it "loads available teams" do
        get new_course_case_simulation_path(course, case_instance)
        expect(assigns(:available_teams)).to include(plaintiff_team, defendant_team)
      end

      it "sets default values" do
        get new_course_case_simulation_path(course, case_instance)
        simulation = assigns(:simulation)
        expect(simulation.status).to eq("setup")
        expect(simulation.total_rounds).to eq(6)
        expect(simulation.current_round).to eq(1)
        expect(simulation.pressure_escalation_rate).to eq("moderate")
      end
    end

    context "when user is student" do
      before { sign_in student }

      it "denies access" do
        get new_course_case_simulation_path(course, case_instance)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get new_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation" do
    let(:valid_params) do
      {
        simulation: {
          plaintiff_team_id: plaintiff_team.id,
          defendant_team_id: defendant_team.id,
          plaintiff_min_acceptable: 100000,
          plaintiff_ideal: 300000,
          defendant_ideal: 50000,
          defendant_max_acceptable: 200000,
          total_rounds: 6,
          pressure_escalation_rate: "moderate",
          simulation_config: {
            client_mood_enabled: "true",
            pressure_escalation_enabled: "true"
          }
        }
      }
    end

    context "when user is instructor" do
      before { sign_in instructor }

      context "with valid parameters" do
        it "creates simulation" do
          expect {
            post course_case_simulation_path(course, case_instance), params: valid_params
          }.to change(Simulation, :count).by(1)
        end

        it "sets correct attributes" do
          post course_case_simulation_path(course, case_instance), params: valid_params

          simulation = case_instance.reload.simulation
          expect(simulation.status).to eq("setup")
          expect(simulation.plaintiff_team).to eq(plaintiff_team)
          expect(simulation.defendant_team).to eq(defendant_team)
          expect(simulation.plaintiff_min_acceptable).to eq(100000)
          expect(simulation.total_rounds).to eq(6)
        end

        it "redirects to case page with success notice" do
          post course_case_simulation_path(course, case_instance), params: valid_params
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:notice]).to include("created successfully")
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {
            simulation: {
              plaintiff_min_acceptable: nil,
              total_rounds: 0
            }
          }
        end

        it "does not create simulation" do
          expect {
            post course_case_simulation_path(course, case_instance), params: invalid_params
          }.not_to change(Simulation, :count)
        end

        it "renders new template with errors" do
          post course_case_simulation_path(course, case_instance), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end
      end
    end

    context "when user is student" do
      before { sign_in student }

      it "denies access" do
        post course_case_simulation_path(course, case_instance), params: valid_params
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /courses/:course_id/cases/:case_id/simulation/edit" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    context "when user is instructor" do
      before do
        sign_in instructor
        plaintiff_team # Force creation of teams
        defendant_team
        # Create case team assignments
        case_instance.case_teams.create!(team: plaintiff_team, role: :plaintiff)
        case_instance.case_teams.create!(team: defendant_team, role: :defendant)
      end

      it "returns success" do
        get edit_course_case_simulation_path(course, case_instance)
        expect(response).to have_http_status(:success)
      end

      it "assigns the simulation" do
        get edit_course_case_simulation_path(course, case_instance)
        expect(assigns(:simulation)).to eq(simulation)
      end

      it "loads teams for assignment" do
        get edit_course_case_simulation_path(course, case_instance)
        expect(assigns(:available_teams)).to be_present
        expect(assigns(:assigned_teams)).to be_present
      end
    end

    context "when case has no simulation" do
      let(:case_without_simulation) { create(:case, course: course, created_by: instructor) }

      before { sign_in instructor }

      it "redirects with error message" do
        get edit_course_case_simulation_path(course, case_without_simulation)
        expect(response).to redirect_to(course_case_path(course, case_without_simulation))
        expect(flash[:alert]).to include("No simulation exists")
      end
    end
  end

  describe "PATCH /courses/:course_id/cases/:case_id/simulation" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        total_rounds: 6)
    end

    let(:update_params) do
      {
        simulation: {
          total_rounds: 8,
          pressure_escalation_rate: "high",
          simulation_config: {
            client_mood_enabled: "false"
          }
        }
      }
    end

    context "when user is instructor" do
      before { sign_in instructor }

      context "with valid parameters" do
        it "updates simulation" do
          patch course_case_simulation_path(course, case_instance), params: update_params

          simulation.reload
          expect(simulation.total_rounds).to eq(8)
          expect(simulation.pressure_escalation_rate).to eq("high")
        end

        it "redirects with success notice" do
          patch course_case_simulation_path(course, case_instance), params: update_params
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:notice]).to include("updated successfully")
        end
      end

      context "with invalid parameters" do
        let(:invalid_params) do
          {simulation: {total_rounds: 0}}
        end

        it "does not update simulation" do
          original_rounds = simulation.total_rounds
          patch course_case_simulation_path(course, case_instance), params: invalid_params
          expect(simulation.reload.total_rounds).to eq(original_rounds)
        end

        it "renders edit template with errors" do
          patch course_case_simulation_path(course, case_instance), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/start" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        plaintiff_min_acceptable: 100000,
        plaintiff_ideal: 300000,
        defendant_ideal: 50000,
        defendant_max_acceptable: 200000,
        total_rounds: 6,
        current_round: 1)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      context "when simulation is ready" do
        it "starts the simulation" do
          post start_course_case_simulation_path(course, case_instance)

          simulation.reload
          expect(simulation.status).to eq("active")
          expect(simulation.start_date).to be_present
        end

        it "creates initial negotiation round" do
          expect {
            post start_course_case_simulation_path(course, case_instance)
          }.to change { simulation.negotiation_rounds.count }.by(1)

          round = simulation.negotiation_rounds.first
          expect(round.round_number).to eq(1)
          expect(round.status).to eq("active")
        end

        it "redirects with success notice" do
          post start_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:notice]).to include("started successfully")
        end
      end

      context "when simulation has validation errors" do
        before do
          simulation.update!(plaintiff_min_acceptable: nil)
        end

        it "does not start simulation" do
          post start_course_case_simulation_path(course, case_instance)
          expect(simulation.reload.status).to eq("setup")
        end

        it "redirects with error message" do
          post start_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Failed to start simulation")
        end
      end

      context "when simulation is already active" do
        before { simulation.update!(status: :active, start_date: Time.current, plaintiff_min_acceptable: 100000, plaintiff_ideal: 300000, defendant_max_acceptable: 200000, defendant_ideal: 50000) }

        it "redirects with error message" do
          post start_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Failed to start simulation")
        end
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/pause" do
    let!(:simulation) do
      create(:simulation, :active,
        case: case_instance,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "pauses the simulation" do
        post pause_course_case_simulation_path(course, case_instance)
        expect(simulation.reload.status).to eq("paused")
      end

      it "redirects with success notice" do
        post pause_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(course_case_path(course, case_instance))
        expect(flash[:notice]).to include("paused")
      end

      context "when simulation is not active" do
        before { simulation.update!(status: :setup) }

        it "redirects with error message" do
          post pause_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Can only pause active simulations")
        end
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/resume" do
    let!(:simulation) do
      create(:simulation, :paused,
        case: case_instance,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "resumes the simulation" do
        post resume_course_case_simulation_path(course, case_instance)
        expect(simulation.reload.status).to eq("active")
      end

      it "redirects with success notice" do
        post resume_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(course_case_path(course, case_instance))
        expect(flash[:notice]).to include("resumed")
      end

      context "when simulation is not paused" do
        before { simulation.update!(status: :active, start_date: Time.current, plaintiff_min_acceptable: 100000, plaintiff_ideal: 300000, defendant_max_acceptable: 200000, defendant_ideal: 50000) }

        it "redirects with error message" do
          post resume_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Can only resume paused simulations")
        end
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/complete" do
    let!(:simulation) do
      create(:simulation, :active,
        case: case_instance,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "completes the simulation" do
        post complete_course_case_simulation_path(course, case_instance)

        simulation.reload
        expect(simulation.status).to eq("completed")
        expect(simulation.end_date).to be_present
      end

      it "redirects with success notice" do
        post complete_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(course_case_path(course, case_instance))
        expect(flash[:notice]).to include("completed successfully")
      end

      context "when simulation is not active or paused" do
        before { simulation.update!(status: :setup) }

        it "redirects with error message" do
          post complete_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Can only complete active or paused simulations")
        end
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/trigger_arbitration" do
    let!(:simulation) do
      create(:simulation, :active,
        case: case_instance,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "triggers arbitration" do
        post trigger_arbitration_course_case_simulation_path(course, case_instance)

        simulation.reload
        expect(simulation.status).to eq("arbitration")
        expect(simulation.end_date).to be_present
      end

      it "redirects with success notice" do
        post trigger_arbitration_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(course_case_path(course, case_instance))
        expect(flash[:notice]).to include("Arbitration triggered")
      end
    end
  end

  describe "POST /courses/:course_id/cases/:case_id/simulation/advance_round" do
    let!(:simulation) do
      create(:simulation, :active,
        case: case_instance,
        current_round: 1,
        total_rounds: 6,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team)
    end

    let!(:completed_round) do
      create(:negotiation_round,
        simulation: simulation,
        round_number: 1,
        status: :completed)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "advances to next round" do
        post advance_round_course_case_simulation_path(course, case_instance)
        expect(simulation.reload.current_round).to eq(2)
      end

      it "creates new negotiation round" do
        expect {
          post advance_round_course_case_simulation_path(course, case_instance)
        }.to change { simulation.negotiation_rounds.count }.by(1)

        new_round = simulation.negotiation_rounds.last
        expect(new_round.round_number).to eq(2)
        expect(new_round.status).to eq("active")
      end

      it "redirects with success notice" do
        post advance_round_course_case_simulation_path(course, case_instance)
        expect(response).to redirect_to(course_case_path(course, case_instance))
        expect(flash[:notice]).to include("Advanced to round 2")
      end

      context "when current round is not completed" do
        before { completed_round.update!(status: :active) }

        it "redirects with error message" do
          post advance_round_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Failed to advance round")
        end
      end

      context "when at maximum rounds" do
        before { simulation.update!(current_round: 6) }

        it "redirects with error message" do
          post advance_round_course_case_simulation_path(course, case_instance)
          expect(response).to redirect_to(course_case_path(course, case_instance))
          expect(flash[:alert]).to include("Failed to advance round")
        end
      end
    end
  end

  describe "GET /courses/:course_id/cases/:case_id/simulation/status" do
    let!(:simulation) do
      create(:simulation,
        case: case_instance,
        status: :setup,
        plaintiff_team: plaintiff_team,
        defendant_team: defendant_team,
        current_round: 1,
        total_rounds: 6)
    end

    context "when user is instructor" do
      before { sign_in instructor }

      it "returns simulation status as JSON" do
        get status_course_case_simulation_path(course, case_instance)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("application/json")
      end

      it "includes simulation details" do
        get status_course_case_simulation_path(course, case_instance)
        json_response = JSON.parse(response.body)

        expect(json_response["simulation"]["id"]).to eq(simulation.id)
        expect(json_response["simulation"]["status"]).to eq("setup")
        expect(json_response["simulation"]["current_round"]).to eq(1)
        expect(json_response["simulation"]["total_rounds"]).to eq(6)
      end

      it "includes action availability" do
        get status_course_case_simulation_path(course, case_instance)
        json_response = JSON.parse(response.body)
        simulation_data = json_response["simulation"]

        expect(simulation_data).to have_key("can_start")
        expect(simulation_data).to have_key("can_pause")
        expect(simulation_data).to have_key("can_resume")
        expect(simulation_data).to have_key("can_complete")
      end
    end
  end

  describe "Direct case route access" do
    let!(:simulation) { create(:simulation, case: case_instance, status: :setup) }

    context "using direct case routes" do
      before { sign_in instructor }

      it "works for new simulation" do
        get new_case_simulation_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "works for editing simulation" do
        get edit_case_simulation_path(case_instance)
        expect(response).to have_http_status(:success)
      end

      it "works for starting simulation" do
        # Setup simulation properly first
        simulation.update!(
          plaintiff_team: plaintiff_team,
          defendant_team: defendant_team,
          plaintiff_min_acceptable: 100000,
          plaintiff_ideal: 300000,
          defendant_ideal: 50000,
          defendant_max_acceptable: 200000
        )

        post start_case_simulation_path(case_instance)
        expect(response).to redirect_to(course_case_path(case_instance.course, case_instance))
      end
    end
  end
end
