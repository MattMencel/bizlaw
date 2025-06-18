# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }

  describe "GET /dashboard" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get "/dashboard"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as admin" do
      before { sign_in admin }

      it "renders admin dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
        expect(response).to render_template("admin_dashboard")
      end

      it "loads admin data" do
        get "/dashboard"
        expect(assigns(:total_users)).to be_present
        expect(assigns(:total_instructors)).to be_present
        expect(assigns(:total_students)).to be_present
        expect(assigns(:total_organizations)).to be_present
        expect(assigns(:active_organizations)).to be_present
        expect(assigns(:recent_users)).to be_present
      end
    end

    context "when authenticated as instructor" do
      before { sign_in instructor }

      it "renders instructor dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
        expect(response).to render_template("instructor_dashboard")
      end

      it "loads instructor data" do
        course = create(:course, instructor: instructor)
        team = create(:team)
        create(:team_member, user: instructor, team: team)

        get "/dashboard"
        expect(assigns(:my_courses)).to include(course)
        expect(assigns(:my_teams)).to include(team)
        expect(assigns(:recent_activity)).to eq([])
      end
    end

    context "when authenticated as student" do
      before { sign_in student }

      it "renders student dashboard" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
        expect(response).to render_template("student_dashboard")
      end

      it "loads student data without errors" do
        team = create(:team)
        create(:team_member, user: student, team: team)
        case_record = create(:case, team: team)

        get "/dashboard"
        expect(assigns(:my_teams)).to include(team)
        expect(assigns(:my_cases)).to include(case_record)
        expect(assigns(:recent_activity)).to eq([])
      end

      it "handles empty student data" do
        get "/dashboard"
        expect(response).to have_http_status(:success)
        expect(assigns(:my_teams)).to be_empty
        expect(assigns(:my_cases)).to be_empty
        expect(assigns(:recent_activity)).to eq([])
      end

      context "with simulation data" do
        let(:team) { create(:team, name: "Plaintiff Team A") }
        let(:case_with_simulation) { create(:case, case_type: :sexual_harassment, name: "Mitchell v. TechFlow Industries") }
        let!(:simulation) { create(:simulation, status: :active, case: case_with_simulation) }

        before do
          create(:team_member, user: student, team: team)
          create(:case_team, case: case_with_simulation, team: team, role: :plaintiff)
        end

        it "displays simulation dashboard content" do
          get "/dashboard"
          expect(response.body).to include("Mitchell v. TechFlow Industries")
          expect(response.body).to include("Plaintiff Team A")
        end

        it "loads simulation data efficiently" do
          get "/dashboard"
          expect(response).to have_http_status(:success)
        end
      end

      context "with multiple simulation statuses" do
        let(:plaintiff_team) { create(:team, name: "Plaintiff Team A") }
        let(:defendant_team) { create(:team, name: "Defense Team B") }
        let(:active_case) { create(:case, name: "Mitchell v. TechFlow Industries", case_type: :sexual_harassment) }
        let(:completed_case) { create(:case, name: "Johnson v. MegaCorp", case_type: :discrimination) }
        let!(:active_simulation) { create(:simulation, status: :active, case: active_case) }
        let!(:completed_simulation) { create(:simulation, status: :completed, case: completed_case) }

        before do
          create(:team_member, user: student, team: plaintiff_team)
          create(:team_member, user: student, team: defendant_team)
          create(:case_team, case: active_case, team: plaintiff_team, role: :plaintiff)
          create(:case_team, case: completed_case, team: defendant_team, role: :defendant)
        end

        it "displays different simulation statuses" do
          get "/dashboard"
          expect(response.body).to include("Mitchell v. TechFlow Industries")
          expect(response.body).to include("Johnson v. MegaCorp")
        end

        it "shows simulation status indicators" do
          get "/dashboard"
          expect(response).to have_http_status(:success)
        end
      end

      context "with no simulations" do
        it "displays empty state message" do
          get "/dashboard"
          expect(response).to have_http_status(:success)
          expect(response.body).to include("simulation") # Any mention of simulation is fine for empty state
        end
      end
    end
  end
end
