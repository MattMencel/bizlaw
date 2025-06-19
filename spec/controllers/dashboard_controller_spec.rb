# frozen_string_literal: true

require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  include Devise::Test::ControllerHelpers
  describe "GET #index" do
    context "when user is not authenticated" do
      it "redirects to login page" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as student" do
      let(:student) { create(:user, role: :student) }
      let(:team1) { create(:team, name: "Plaintiff Team A") }
      let(:team2) { create(:team, name: "Defense Team B") }
      let(:case1) { create(:case, case_type: :sexual_harassment, title: "Mitchell v. TechFlow Industries") }
      let(:case2) { create(:case, case_type: :discrimination, title: "Johnson v. MegaCorp") }

      before do
        sign_in student
        create(:team_member, user: student, team: team1)
        create(:team_member, user: student, team: team2)
        create(:case_team, case: case1, team: team1, role: :plaintiff)
        create(:case_team, case: case2, team: team2, role: :defendant)
      end

      it "renders student dashboard template" do
        get :index
        expect(response).to render_template("student_dashboard")
      end

      it "loads student-specific data" do
        get :index
        expect(assigns(:my_teams)).to include(team1, team2)
        expect(assigns(:my_cases)).to include(case1, case2)
        expect(assigns(:recent_activity)).to eq([])
      end

      it "includes associated cases with teams" do
        get :index
        my_teams = assigns(:my_teams)
        expect(my_teams.first.cases).to be_loaded
      end

      it "includes associated documents with cases" do
        get :index
        my_cases = assigns(:my_cases)
        expect(my_cases.first.documents).to be_loaded
      end
    end

    context "when user is authenticated as instructor" do
      let(:instructor) { create(:user, role: :instructor) }
      let(:course) { create(:course) }
      let(:team) { create(:team) }

      before do
        sign_in instructor
        course.instructor = instructor
        course.save!
        create(:team_member, user: instructor, team: team)
      end

      it "renders instructor dashboard template" do
        get :index
        expect(response).to render_template("instructor_dashboard")
      end

      it "loads instructor-specific data" do
        get :index
        expect(assigns(:my_courses)).to include(course)
        expect(assigns(:my_teams)).to include(team)
        expect(assigns(:recent_activity)).to eq([])
      end
    end

    context "when user is authenticated as admin" do
      let(:admin) { create(:user, role: :admin) }
      let!(:organization) { create(:organization, active: true) }
      let!(:instructor) { create(:user, role: :instructor) }
      let!(:student) { create(:user, role: :student) }

      before do
        sign_in admin
      end

      it "renders admin dashboard template" do
        get :index
        expect(response).to render_template("admin_dashboard")
      end

      it "loads admin-specific data" do
        get :index
        expect(assigns(:total_users)).to eq(User.count)
        expect(assigns(:total_instructors)).to eq(1)
        expect(assigns(:total_students)).to eq(1)
        expect(assigns(:total_organizations)).to eq(1)
        expect(assigns(:active_organizations)).to eq(1)
        expect(assigns(:recent_users)).to include(instructor, student)
      end

      context "with user search parameter" do
        it "returns matching users for impersonation" do
          get :index, params: {user_search: instructor.first_name}
          expect(assigns(:search_results)).to include(instructor)
          expect(assigns(:search_results)).not_to include(admin)
        end

        it "searches by email" do
          get :index, params: {user_search: student.email.split("@").first}
          expect(assigns(:search_results)).to include(student)
        end

        it "limits search results to 10" do
          create_list(:user, 15, role: :student)
          get :index, params: {user_search: "test"}
          expect(assigns(:search_results).count).to be <= 10
        end
      end
    end
  end

  describe "simulation dashboard specific functionality" do
    let(:student) { create(:user, role: :student) }
    let(:team) { create(:team) }
    let(:case_with_simulation) { create(:case, :with_simulation) }

    before do
      sign_in student
      create(:team_member, user: student, team: team)
      create(:case_team, case: case_with_simulation, team: team, role: :plaintiff)
    end

    it "includes simulation data in student dashboard" do
      get :index
      expect(assigns(:my_teams).first.cases.first.simulation).to be_present
    end

    context "with active simulations" do
      let!(:active_simulation) { create(:simulation, status: :active, case: case_with_simulation) }

      it "identifies active simulations for the student" do
        get :index
        active_cases = assigns(:my_cases).joins(:simulation).where(simulations: {status: :active})
        expect(active_cases).to include(case_with_simulation)
      end
    end

    context "with completed simulations" do
      let!(:completed_simulation) { create(:simulation, status: :completed, case: case_with_simulation) }

      it "identifies completed simulations for the student" do
        get :index
        completed_cases = assigns(:my_cases).joins(:simulation).where(simulations: {status: :completed})
        expect(completed_cases).to include(case_with_simulation)
      end
    end
  end

  describe "dashboard performance" do
    let(:student) { create(:user, role: :student) }

    before do
      sign_in student
      # Create test data
      teams = create_list(:team, 3)
      teams.each { |team| create(:team_member, user: student, team: team) }
      teams.each { |team| create(:case, :with_simulation, team: team) }
    end

    it "loads dashboard data without errors" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "error handling" do
    let(:student) { create(:user, role: :student) }

    before do
      sign_in student
    end

    it "handles missing simulation data gracefully" do
      allow(student).to receive(:teams).and_raise(ActiveRecord::StatementInvalid.new("Connection lost"))

      expect { get :index }.not_to raise_error
    end
  end
end
