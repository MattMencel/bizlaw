# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Teams", type: :request do
  let(:student) { create(:user, :student) }
  let(:instructor) { create(:user, :instructor) }
  let(:admin) { create(:user, :admin) }
  let(:course) { create(:course, instructor: instructor) }

  before do
    # Ensure users are enrolled in the course
    create(:course_enrollment, user: student, course: course, status: "active")
    create(:course_enrollment, user: instructor, course: course, status: "active")
  end

  describe "GET /teams" do
    let(:other_student) { create(:user, :student) }
    let(:course2) { create(:course, instructor: instructor) }

    # Create teams directly without going through simulation factory to avoid auto-team creation
    let!(:student_team) do
      # Create a case and simulation but skip the auto team creation
      case1 = create(:case, course: course, created_by: instructor)
      # Use insert to bypass all callbacks and validations
      sim1_id = SecureRandom.uuid
      Simulation.connection.execute(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{sim1_id}', '#{case1.id}', 6, 1, 'setup', NOW(), NOW())"
      )
      sim1 = Simulation.find(sim1_id)
      create(:team, owner: student, simulation: sim1)
    end

    let!(:instructor_team) do
      case2 = create(:case, course: course, created_by: instructor)
      sim2_id = SecureRandom.uuid
      Simulation.connection.execute(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{sim2_id}', '#{case2.id}', 6, 1, 'setup', NOW(), NOW())"
      )
      sim2 = Simulation.find(sim2_id)
      create(:team, owner: instructor, simulation: sim2)
    end

    let!(:shared_team) do
      case3 = create(:case, course: course, created_by: instructor)
      sim3_id = SecureRandom.uuid
      Simulation.connection.execute(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{sim3_id}', '#{case3.id}', 6, 1, 'setup', NOW(), NOW())"
      )
      sim3 = Simulation.find(sim3_id)
      create(:team, owner: instructor, simulation: sim3)
    end

    let!(:course2_team) do
      case4 = create(:case, course: course2, created_by: instructor)
      sim4_id = SecureRandom.uuid
      Simulation.connection.execute(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{sim4_id}', '#{case4.id}', 6, 1, 'setup', NOW(), NOW())"
      )
      sim4 = Simulation.find(sim4_id)
      create(:team, owner: instructor, simulation: sim4)
    end

    let!(:other_student_team) do
      # Enroll the other student first
      create(:course_enrollment, user: other_student, course: course, status: "active")
      case5 = create(:case, course: course, created_by: instructor)
      sim5_id = SecureRandom.uuid
      Simulation.connection.execute(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{sim5_id}', '#{case5.id}', 6, 1, 'setup', NOW(), NOW())"
      )
      sim5 = Simulation.find(sim5_id)
      create(:team, owner: other_student, simulation: sim5)
    end

    before do
      # Ensure course2 exists with proper enrollment
      create(:course_enrollment, user: instructor, course: course2, status: "active")

      # Add student as member to their own team
      create(:team_member, team: student_team, user: student)
      # Add student as member to a shared team
      create(:team_member, team: shared_team, user: student)
    end

    context "when user is a student" do
      before { sign_in student }

      it "shows only teams where the student is a member" do
        get teams_path
        expect(response).to have_http_status(:success)
        expect(assigns(:teams)).to include(student_team, shared_team)
        expect(assigns(:teams)).not_to include(instructor_team, other_student_team)
      end

      it "returns correct teams in JSON format" do
        get teams_path, headers: {"Accept" => "application/json"}
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        team_ids = json_response["data"].map { |team| team["id"] }
        expect(team_ids).to include(student_team.id, shared_team.id)
        expect(team_ids).not_to include(instructor_team.id, other_student_team.id)
      end
    end

    context "when user is an instructor" do
      before { sign_in instructor }

      it "shows all teams" do
        get teams_path
        expect(response).to have_http_status(:success)
        expect(assigns(:teams)).to include(student_team, instructor_team, other_student_team, shared_team, course2_team)
      end

      it "returns all teams in JSON format" do
        get teams_path, headers: {"Accept" => "application/json"}
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        team_ids = json_response["data"].map { |team| team["id"] }
        expect(team_ids).to include(student_team.id, instructor_team.id, other_student_team.id, shared_team.id, course2_team.id)
      end

      context "with view parameter" do
        it "supports hierarchical view" do
          get teams_path, params: {view: "hierarchical"}
          expect(response).to have_http_status(:success)
          expect(assigns(:teams_by_course)).to be_present
        end

        it "supports simulation view" do
          get teams_path, params: {view: "simulation"}
          expect(response).to have_http_status(:success)
          expect(assigns(:teams_by_simulation)).to be_present
        end

        it "defaults to flat view" do
          get teams_path
          expect(response).to have_http_status(:success)
          expect(assigns(:teams)).to be_present
        end
      end

      context "with filters" do
        it "filters by course" do
          get teams_path, params: {course_id: course.id}
          expect(response).to have_http_status(:success)
          expect(assigns(:teams)).not_to include(course2_team)
        end

        it "filters by role" do
          course2_team.update!(role: "defendant")
          get teams_path, params: {role: "defendant"}
          expect(response).to have_http_status(:success)
          expect(assigns(:teams)).to include(course2_team)
        end
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "shows all teams" do
        get teams_path
        expect(response).to have_http_status(:success)
        expect(assigns(:teams)).to include(student_team, instructor_team, other_student_team, shared_team, course2_team)
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in page" do
        get teams_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /teams/:id" do
    let!(:team) do
      case_record = create(:case, course: course, created_by: instructor)
      sim_id = Simulation.connection.insert(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{SecureRandom.uuid}', '#{case_record.id}', 6, 1, 'setup', NOW(), NOW()) RETURNING id"
      )
      sim = Simulation.find(sim_id)
      create(:team, owner: instructor, simulation: sim)
    end
    let!(:other_student) { create(:user, :student) }

    before do
      create(:course_enrollment, user: other_student, course: course, status: "active")
      create(:team_member, team: team, user: student)
    end

    context "when student is a member of the team" do
      before { sign_in student }

      it "allows access to the team" do
        get team_path(team)
        expect(response).to have_http_status(:success)
        expect(assigns(:team)).to eq(team)
      end
    end

    context "when student is not a member of the team" do
      before { sign_in other_student }

      it "returns 404 or redirects when accessing team they're not a member of" do
        get team_path(team)
        expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
      end
    end

    context "when user is an instructor" do
      before { sign_in instructor }

      it "allows access to any team" do
        get team_path(team)
        expect(response).to have_http_status(:success)
        expect(assigns(:team)).to eq(team)
      end
    end
  end

  describe "DELETE /teams/:id" do
    context "when deleting team from course context" do
      let(:team) do
        case_record = create(:case, course: course, created_by: instructor)
        sim_id = Simulation.connection.insert(
          "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
           VALUES ('#{SecureRandom.uuid}', '#{case_record.id}', 6, 1, 'setup', NOW(), NOW()) RETURNING id"
        )
        sim = Simulation.find(sim_id)
        create(:team, owner: instructor, simulation: sim)
      end

      before do
        create(:team_member, team: team, user: instructor)
        sign_in instructor
      end

      it "deletes the team and redirects to course page" do
        expect {
          delete course_team_path(course, team)
        }.to change(Team, :count).by(-1)

        expect(response).to redirect_to(course_path(course))
        expect(flash[:notice]).to eq("Team was successfully deleted.")
      end
    end

    context "when student tries to delete team they don't own" do
      let(:other_student) { create(:user, :student) }
      let(:team) do
        case_record = create(:case, course: course, created_by: instructor)
        sim_id = Simulation.connection.insert(
          "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
           VALUES ('#{SecureRandom.uuid}', '#{case_record.id}', 6, 1, 'setup', NOW(), NOW()) RETURNING id"
        )
        sim = Simulation.find(sim_id)
        create(:team, owner: instructor, simulation: sim)
      end

      before do
        create(:course_enrollment, user: other_student, course: course, status: "active")
        sign_in other_student
      end

      it "prevents deletion due to authorization (returns 404)" do
        delete course_team_path(course, team)
        expect(response).to have_http_status(:not_found).or have_http_status(:redirect)
      end
    end
  end

  describe "GET /courses/:course_id/teams/:id/edit" do
    let(:team) do
      case_record = create(:case, course: course, created_by: instructor)
      sim_id = Simulation.connection.insert(
        "INSERT INTO simulations (id, case_id, total_rounds, current_round, status, created_at, updated_at)
         VALUES ('#{SecureRandom.uuid}', '#{case_record.id}', 6, 1, 'setup', NOW(), NOW()) RETURNING id"
      )
      sim = Simulation.find(sim_id)
      create(:team, owner: instructor, simulation: sim)
    end

    before do
      create(:team_member, team: team, user: instructor)
      sign_in instructor
    end

    it "renders edit form with correct delete link" do
      get edit_course_team_path(course, team)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-turbo-method="delete"')
      # The delete link should use the course-nested route
      expect(response.body).to include(course_team_path(course, team))
    end
  end
end
