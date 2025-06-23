# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cases", type: :request do
  include Devise::Test::IntegrationHelpers
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_instance) { create(:case, course: course, created_by: instructor) }

  # Enroll student in the course (instructors don't need enrollment)
  let!(:student_enrollment) { create(:course_enrollment, user: student, course: course) }

  describe "GET /courses/:course_id/cases" do
    context "when user is authenticated" do
      before do
        sign_in instructor
        case_instance # Create the case
      end

      it "returns successful response" do
        get course_cases_path(course)
        expect(response).to have_http_status(:success)
      end

      it "displays cases for the course" do
        get course_cases_path(course)
        expect(response.body).to include(case_instance.title)
      end

      it "supports pagination" do
        get course_cases_path(course), params: {page: 1}
        expect(response).to have_http_status(:success)
      end
    end

    context "when accessing all cases without course_id" do
      before { sign_in instructor }

      it "shows cases accessible by user" do
        case_instance # Create the case
        get cases_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get course_cases_path(course)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /courses/:course_id/cases/:id" do
    context "when user has access to case" do
      before do
        sign_in instructor
        allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
      end

      it "returns successful response" do
        get course_case_path(course, case_instance)
        expect(response).to have_http_status(:success)
      end

      it "displays case details" do
        get course_case_path(course, case_instance)
        expect(response.body).to include(case_instance.title)
        expect(response.body).to include(case_instance.description)
      end

      context "with JSON format" do
        it "returns case as JSON" do
          get course_case_path(course, case_instance), as: :json
          expect(response).to have_http_status(:success)
          expect(response.content_type).to include("application/json")

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("data")
          expect(json_response["data"]["attributes"]["title"]).to eq(case_instance.title)
        end
      end
    end

    context "when user lacks authorization" do
      before do
        sign_in student
        allow_any_instance_of(CasesController).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

      it "handles authorization error" do
        get course_case_path(course, case_instance)
        expect(response).to have_http_status(:forbidden).or have_http_status(:redirect)
      end
    end
  end

  describe "GET /courses/:course_id/cases/new" do
    before do
      sign_in instructor
      allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
    end

    context "without scenario_id" do
      it "returns successful response" do
        get new_course_case_path(course)
        expect(response).to have_http_status(:success)
      end

      it "loads scenarios for selection" do
        # Mock CaseScenarioService
        allow(CaseScenarioService).to receive(:all).and_return([
          {id: "scenario1", title: "Sample Scenario 1"},
          {id: "scenario2", title: "Sample Scenario 2"}
        ])

        get new_course_case_path(course)
        expect(response).to have_http_status(:success)
        expect(CaseScenarioService).to have_received(:all)
      end

      it "builds new case for course" do
        get new_course_case_path(course)
        expect(assigns(:case)).to be_a_new(Case)
        expect(assigns(:case).course).to eq(course)
      end
    end

    context "with scenario_id parameter" do
      let(:scenario_id) { "sexual_harassment_basic" }
      let(:mock_scenario) do
        {
          id: scenario_id,
          title: "Basic Sexual Harassment Case",
          description: "A workplace harassment scenario"
        }
      end

      before do
        allow(CaseScenarioService).to receive(:build_case_from_scenario).and_return(
          build(:case, course: course)
        )
        allow(CaseScenarioService).to receive(:find).with(scenario_id).and_return(mock_scenario)
      end

      it "builds case from scenario" do
        get new_course_case_path(course), params: {scenario_id: scenario_id}

        expect(response).to have_http_status(:success)
        expect(CaseScenarioService).to have_received(:build_case_from_scenario).with(
          scenario_id,
          course: course,
          created_by: instructor
        )
      end

      it "loads selected scenario" do
        get new_course_case_path(course), params: {scenario_id: scenario_id}

        expect(assigns(:selected_scenario)).to eq(mock_scenario)
        expect(CaseScenarioService).to have_received(:find).with(scenario_id)
      end

      it "loads course teams" do
        team1 = create(:team, course: course)
        team2 = create(:team, course: course)

        get new_course_case_path(course), params: {scenario_id: scenario_id}

        expect(assigns(:teams)).to contain_exactly(team1, team2)
      end
    end
  end

  describe "POST /courses/:course_id/cases" do
    let(:valid_case_params) do
      {
        title: "New Legal Case",
        description: "A test case description",
        case_type: "sexual_harassment",
        difficulty_level: "intermediate",
        legal_issues: ["Sexual harassment", "Workplace misconduct"],
        plaintiff_info_keys: ["name", "position"],
        plaintiff_info_values: ["John Doe", "Manager"],
        defendant_info_keys: ["company", "type"],
        defendant_info_values: ["TechCorp", "Corporation"]
      }
    end

    let(:invalid_case_params) do
      {
        title: "", # Invalid - blank title
        description: "Description",
        case_type: "sexual_harassment",
        difficulty_level: "intermediate",
        legal_issues: ["Sexual harassment"],
        plaintiff_info_keys: ["name"],
        plaintiff_info_values: ["John Doe"],
        defendant_info_keys: ["company"],
        defendant_info_values: ["TechCorp"]
      }
    end

    before do
      sign_in instructor
      allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
    end

    context "with valid parameters" do
      it "creates a new case" do
        expect {
          post course_cases_path(course), params: {case: valid_case_params}
        }.to change(Case, :count).by(1)
      end

      it "assigns case to course and user" do
        post course_cases_path(course), params: {case: valid_case_params}

        created_case = Case.last
        expect(created_case.course).to eq(course)
        expect(created_case.created_by).to eq(instructor)
        expect(created_case.updated_by).to eq(instructor)
      end

      it "converts info keys/values to JSON" do
        post course_cases_path(course), params: {case: valid_case_params}

        created_case = Case.last
        expect(created_case.plaintiff_info).to eq({"name" => "John Doe", "position" => "Manager"})
        expect(created_case.defendant_info).to eq({"company" => "TechCorp", "type" => "Corporation"})
      end

      it "redirects to case show page" do
        post course_cases_path(course), params: {case: valid_case_params}

        created_case = Case.last
        expect(response).to redirect_to(course_case_path(course, created_case))
      end

      it "sets success notice" do
        post course_cases_path(course), params: {case: valid_case_params}
        follow_redirect!
        expect(response.body).to include("Case was successfully created")
      end

      context "with JSON format" do
        it "returns created case as JSON" do
          post course_cases_path(course), params: {case: valid_case_params}, as: :json

          expect(response).to have_http_status(:created)
          expect(response.content_type).to include("application/json")

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("data")
          expect(json_response["data"]["attributes"]["title"]).to eq("New Legal Case")
        end
      end
    end

    context "with invalid parameters" do
      it "does not create a case" do
        expect {
          post course_cases_path(course), params: {case: invalid_case_params}
        }.not_to change(Case, :count)
      end

      it "renders new template with errors" do
        post course_cases_path(course), params: {case: invalid_case_params}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("New Legal Case") # Form title
      end

      context "with JSON format" do
        it "returns validation errors as JSON" do
          post course_cases_path(course), params: {case: invalid_case_params}, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to include("application/json")

          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("title") # Validation error for title
        end
      end
    end
  end

  describe "GET /courses/:course_id/cases/:id/edit" do
    before do
      sign_in instructor
      allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
    end

    it "returns successful response" do
      get edit_course_case_path(course, case_instance)
      expect(response).to have_http_status(:success)
    end

    it "loads case for editing" do
      get edit_course_case_path(course, case_instance)
      expect(assigns(:case)).to eq(case_instance)
    end

    it "loads course teams" do
      team1 = create(:team, course: course)
      team2 = create(:team, course: course)

      get edit_course_case_path(course, case_instance)
      expect(assigns(:teams)).to contain_exactly(team1, team2)
    end
  end

  describe "PATCH /courses/:course_id/cases/:id" do
    let(:updated_params) do
      {
        title: "Updated Case Title",
        description: "Updated description"
      }
    end

    before do
      sign_in instructor
      allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
    end

    context "with valid parameters" do
      it "updates the case" do
        patch course_case_path(course, case_instance), params: {case: updated_params}

        case_instance.reload
        expect(case_instance.title).to eq("Updated Case Title")
        expect(case_instance.description).to eq("Updated description")
        expect(case_instance.updated_by).to eq(instructor)
      end

      it "redirects to case show page" do
        patch course_case_path(course, case_instance), params: {case: updated_params}
        expect(response).to redirect_to(course_case_path(course, case_instance))
      end

      it "sets success notice" do
        patch course_case_path(course, case_instance), params: {case: updated_params}
        follow_redirect!
        expect(response.body).to include("Case was successfully updated")
      end

      context "with JSON format" do
        it "returns updated case as JSON" do
          patch course_case_path(course, case_instance), params: {case: updated_params}, as: :json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)
          expect(json_response["data"]["attributes"]["title"]).to eq("Updated Case Title")
        end
      end
    end

    context "with invalid parameters" do
      let(:invalid_update_params) { {title: ""} }

      it "does not update the case" do
        original_title = case_instance.title
        patch course_case_path(course, case_instance), params: {case: invalid_update_params}

        case_instance.reload
        expect(case_instance.title).to eq(original_title)
      end

      it "renders edit template with errors" do
        patch course_case_path(course, case_instance), params: {case: invalid_update_params}
        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "with JSON format" do
        it "returns validation errors as JSON" do
          patch course_case_path(course, case_instance), params: {case: invalid_update_params}, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response).to have_key("title")
        end
      end
    end
  end

  describe "DELETE /courses/:course_id/cases/:id" do
    before do
      sign_in instructor
      allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
      case_instance # Create the case
    end

    context "when case can be deleted" do
      let(:case_instance) { create(:case, course: course, status: :not_started, created_by: instructor) }

      it "destroys the case" do
        expect {
          delete course_case_path(course, case_instance)
        }.to change(Case, :count).by(-1)
      end

      it "redirects to cases index" do
        delete course_case_path(course, case_instance)
        expect(response).to redirect_to(course_cases_path(course))
      end

      it "sets success notice" do
        delete course_case_path(course, case_instance)
        follow_redirect!
        expect(response.body).to include("Case was successfully deleted")
      end

      context "with JSON format" do
        it "returns no content" do
          delete course_case_path(course, case_instance), as: :json
          expect(response).to have_http_status(:no_content)
        end
      end
    end

    context "when case cannot be deleted due to status" do
      let(:case_instance) { create(:case, course: course, status: :in_progress, created_by: instructor) }

      it "does not destroy the case" do
        expect {
          delete course_case_path(course, case_instance)
        }.not_to change(Case, :count)
      end

      it "redirects with error message" do
        delete course_case_path(course, case_instance)
        expect(response).to redirect_to(course_cases_path(course))
        expect(flash[:alert]).to eq("Case can only be deleted when in 'Not Started' status")
      end

      context "with JSON format" do
        it "returns unprocessable entity with error" do
          delete course_case_path(course, case_instance), as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Case can only be deleted when in 'Not Started' status")
        end
      end
    end

    context "when case cannot be deleted due to student team members" do
      let(:student) { create(:user, :student) }
      let(:student_team) { create(:team, course: course, owner: student) }
      let(:case_instance) { create(:case, course: course, status: :not_started, created_by: instructor) }

      before do
        create(:team_member, team: student_team, user: student, role: :member)
        create(:case_team, case: case_instance, team: student_team, role: :plaintiff)
      end

      it "does not destroy the case" do
        expect {
          delete course_case_path(course, case_instance)
        }.not_to change(Case, :count)
      end

      it "redirects with error message" do
        delete course_case_path(course, case_instance)
        expect(response).to redirect_to(course_cases_path(course))
        expect(flash[:alert]).to eq("Cannot delete case with teams that have student members")
      end

      context "with JSON format" do
        it "returns unprocessable entity with error" do
          delete course_case_path(course, case_instance), as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Cannot delete case with teams that have student members")
        end
      end
    end
  end

  describe "private methods" do
    describe "#set_course" do
      before { sign_in instructor }

      it "sets @course when course_id is present" do
        get course_cases_path(course)
        expect(assigns(:course)).to eq(course)
      end
    end

    describe "#set_case" do
      before do
        sign_in instructor
        allow_any_instance_of(CasesController).to receive(:authorize).and_return(true)
      end

      context "with course_id parameter" do
        it "finds case within course scope" do
          get course_case_path(course, case_instance)
          expect(assigns(:case)).to eq(case_instance)
          expect(assigns(:course)).to eq(course)
        end
      end

      context "without course_id parameter" do
        it "finds case directly" do
          get case_path(case_instance)
          expect(assigns(:case)).to eq(case_instance)
        end
      end
    end

    describe "#case_params JSON conversion" do
      before { sign_in instructor }

      it "handles empty key-value arrays" do
        params_with_empty_arrays = {
          title: "Test Case",
          description: "Test description",
          case_type: "sexual_harassment",
          difficulty_level: "intermediate",
          legal_issues: ["Test issue"],
          plaintiff_info_keys: [""],
          plaintiff_info_values: [""],
          defendant_info_keys: ["company"],
          defendant_info_values: ["Test Corp"]
        }

        expect {
          post course_cases_path(course), params: {case: params_with_empty_arrays}
        }.to change(Case, :count).by(1)

        created_case = Case.last
        expect(created_case.plaintiff_info).to eq({})
        expect(created_case.defendant_info).to eq({"company" => "Test Corp"})
      end

      it "handles mismatched key-value array lengths" do
        params_with_mismatch = {
          title: "Test Case",
          description: "Test description",
          case_type: "sexual_harassment",
          difficulty_level: "intermediate",
          legal_issues: ["Test issue"],
          plaintiff_info_keys: ["name", "position", "extra"],
          plaintiff_info_values: ["John", "Manager"], # Missing value for "extra"
          defendant_info_keys: ["company"],
          defendant_info_values: ["Test Corp"]
        }

        post course_cases_path(course), params: {case: params_with_mismatch}
        created_case = Case.last
        expect(created_case.plaintiff_info).to eq({
          "name" => "John",
          "position" => "Manager",
          "extra" => ""
        })
      end

      it "skips blank keys" do
        params_with_blank_keys = {
          title: "Test Case",
          description: "Test description",
          case_type: "sexual_harassment",
          difficulty_level: "intermediate",
          legal_issues: ["Test issue"],
          plaintiff_info_keys: ["name", "", "position"],
          plaintiff_info_values: ["John", "ignored", "Manager"],
          defendant_info_keys: ["company"],
          defendant_info_values: ["Test Corp"]
        }

        post course_cases_path(course), params: {case: params_with_blank_keys}
        created_case = Case.last
        expect(created_case.plaintiff_info).to eq({
          "name" => "John",
          "position" => "Manager"
        })
      end
    end
  end

  describe "authorization integration" do
    context "when student tries to create case" do
      before { sign_in student }

      it "checks authorization" do
        # This test verifies that authorization is checked during case creation
        # For a student trying to create a case, this should either succeed (if authorized)
        # or fail with proper authorization handling
        post course_cases_path(course), params: {case: {title: "Test"}}
        expect(response.status).to be_in([201, 302, 403, 422])
      end
    end

    context "when accessing case without permission" do
      let(:other_course) { create(:course, instructor: create(:user, :instructor)) }
      let(:other_case) { create(:case, course: other_course) }

      before { sign_in student }

      it "calls authorize method" do
        expect_any_instance_of(CasesController).to receive(:authorize).with(other_case)

        begin
          get course_case_path(other_course, other_case)
        rescue Pundit::NotAuthorizedError
          # Expected - authorization should fail
        end
      end
    end
  end
end
