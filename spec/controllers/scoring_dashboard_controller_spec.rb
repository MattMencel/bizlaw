# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScoringDashboardController, type: :controller do
  let(:organization) { create(:organization) }
  let(:course) { create(:course, organization: organization) }
  let(:student) { create(:user, :student, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:case_record) { create(:case, :sexual_harassment, course: course) }
  let(:simulation) { create(:simulation, case: case_record) }
  let(:team) { create(:team, course: course) }
  let!(:team_member) { create(:team_member, team: team, user: student) }
  let!(:case_team) { create(:case_team, case: case_record, team: team, role: "plaintiff") }

  describe "GET #index" do
    context "when user is a student" do
      before { sign_in student }

      it "renders the student scoring dashboard" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template("scoring_dashboard/student_index")
      end

      it "loads student's performance data" do
        performance_score = create(:performance_score, 
          simulation: simulation, 
          team: team, 
          user: student,
          total_score: 85,
          settlement_quality_score: 32,
          legal_strategy_score: 24,
          collaboration_score: 16,
          efficiency_score: 8,
          speed_bonus: 3,
          creative_terms_score: 2
        )

        get :index

        expect(assigns(:my_scores)).to include(performance_score)
        expect(assigns(:current_simulation_score)).to eq(performance_score)
        expect(assigns(:performance_trends)).to be_present
      end

      it "handles student with no scores gracefully" do
        get :index
        
        expect(assigns(:my_scores)).to be_empty
        expect(assigns(:current_simulation_score)).to be_nil
        expect(response).to have_http_status(:success)
      end

      it "calculates correct performance metrics" do
        create(:performance_score, 
          simulation: simulation, 
          team: team, 
          user: student,
          total_score: 88,
          settlement_quality_score: 35,
          legal_strategy_score: 28,
          collaboration_score: 15,
          efficiency_score: 7,
          speed_bonus: 3
        )

        get :index

        expect(assigns(:performance_summary)).to include(
          total_score: 88,
          grade: "B",
          percentile: be_a(Numeric),
          rank: be_a(Numeric)
        )
      end
    end

    context "when user is an instructor" do
      before { sign_in instructor }

      it "renders the instructor scoring dashboard" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template("scoring_dashboard/instructor_index")
      end

      it "loads class performance data" do
        # Create multiple students with scores
        students = create_list(:user, 5, :student, organization: organization)
        students.each_with_index do |student, index|
          team = create(:team, course: course)
          create(:team_member, team: team, user: student)
          create(:case_team, case: case_record, team: team, role: index.even? ? "plaintiff" : "defendant")
          create(:performance_score, 
            simulation: simulation, 
            team: team, 
            user: student,
            total_score: 70 + (index * 5)
          )
        end

        get :index

        expect(assigns(:class_performance_data)).to be_present
        expect(assigns(:class_averages)).to include(
          :average_total_score,
          :average_settlement_score,
          :average_strategy_score,
          :average_collaboration_score
        )
        expect(assigns(:students_needing_help)).to be_present
      end

      it "filters performance data by simulation" do
        simulation2 = create(:simulation, case: create(:case, course: course))
        
        # Create scores for different simulations
        create(:performance_score, simulation: simulation, team: team, user: student, total_score: 85)
        create(:performance_score, simulation: simulation2, team: team, user: student, total_score: 90)

        get :index, params: { simulation_id: simulation.id }

        expect(assigns(:filtered_simulation)).to eq(simulation)
        expect(assigns(:class_performance_data).size).to eq(1)
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET #performance_data" do
    before { sign_in student }

    it "returns JSON performance data for student" do
      performance_score = create(:performance_score, 
        simulation: simulation, 
        team: team, 
        user: student,
        total_score: 85,
        settlement_quality_score: 32,
        legal_strategy_score: 24,
        collaboration_score: 16,
        efficiency_score: 8
      )

      get :performance_data, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include(
        "total_score" => 85,
        "grade" => "B",
        "breakdown" => hash_including(
          "settlement_quality" => hash_including("score" => 32, "max_points" => 40),
          "legal_strategy" => hash_including("score" => 24, "max_points" => 30),
          "collaboration" => hash_including("score" => 16, "max_points" => 20),
          "efficiency" => hash_including("score" => 8, "max_points" => 10)
        )
      )
    end

    it "returns empty data when no scores exist" do
      get :performance_data, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include(
        "total_score" => 0,
        "grade" => "Not Yet Scored",
        "breakdown" => {}
      )
    end

    it "includes team comparison data" do
      # Create teammate scores
      teammate = create(:user, :student, organization: organization)
      create(:team_member, team: team, user: teammate)
      
      create(:performance_score, simulation: simulation, team: team, user: student, total_score: 85)
      create(:performance_score, simulation: simulation, team: team, user: teammate, total_score: 78)

      get :performance_data, format: :json, params: { include_team: true }

      json_response = JSON.parse(response.body)
      expect(json_response).to include("team_comparison")
      expect(json_response["team_comparison"]).to include(
        "team_average" => be_a(Numeric),
        "my_rank_in_team" => be_a(Numeric),
        "team_member_count" => 2
      )
    end
  end

  describe "GET #trends" do
    before { sign_in student }

    it "returns trend data over multiple rounds" do
      # Create performance scores for different rounds
      6.times do |round|
        create(:performance_score, 
          simulation: simulation, 
          team: team, 
          user: student,
          total_score: 60 + (round * 5),
          settlement_quality_score: 20 + (round * 2),
          scored_at: round.days.ago
        )
      end

      get :trends, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include("trend_data")
      expect(json_response["trend_data"]).to be_an(Array)
      expect(json_response["trend_data"].length).to eq(6)
      
      first_point = json_response["trend_data"].first
      expect(first_point).to include(
        "date" => be_a(String),
        "total_score" => be_a(Numeric),
        "settlement_quality_score" => be_a(Numeric)
      )
    end

    it "includes improvement analysis" do
      # Create improving scores
      create(:performance_score, simulation: simulation, team: team, user: student, 
             total_score: 65, scored_at: 5.days.ago)
      create(:performance_score, simulation: simulation, team: team, user: student, 
             total_score: 75, scored_at: 3.days.ago)
      create(:performance_score, simulation: simulation, team: team, user: student, 
             total_score: 85, scored_at: 1.day.ago)

      get :trends, format: :json

      json_response = JSON.parse(response.body)
      expect(json_response).to include("improvement_analysis")
      expect(json_response["improvement_analysis"]).to include(
        "overall_trend" => "improving",
        "total_improvement" => 20,
        "average_improvement_per_update" => be_a(Numeric)
      )
    end
  end

  describe "GET #class_analytics" do
    before { sign_in instructor }

    it "returns class-wide analytics for instructors" do
      # Create multiple students with performance data
      5.times do |i|
        student = create(:user, :student, organization: organization)
        team = create(:team, course: course)
        create(:team_member, team: team, user: student)
        create(:case_team, case: case_record, team: team, role: i.even? ? "plaintiff" : "defendant")
        create(:performance_score, 
          simulation: simulation, 
          team: team, 
          user: student,
          total_score: 70 + (i * 4),
          settlement_quality_score: 25 + i,
          legal_strategy_score: 20 + i,
          collaboration_score: 15 + i
        )
      end

      get :class_analytics, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to include(
        "class_averages" => hash_including(
          "total_score" => be_a(Numeric),
          "settlement_quality" => be_a(Numeric),
          "legal_strategy" => be_a(Numeric),
          "collaboration" => be_a(Numeric)
        ),
        "distribution" => be_an(Array),
        "top_performers" => be_an(Array),
        "students_needing_help" => be_an(Array)
      )
    end

    it "includes plaintiff vs defendant comparison" do
      # Create plaintiff and defendant teams with different performance
      plaintiff_student = create(:user, :student, organization: organization)
      defendant_student = create(:user, :student, organization: organization)
      
      plaintiff_team = create(:team, course: course)
      defendant_team = create(:team, course: course)
      
      create(:team_member, team: plaintiff_team, user: plaintiff_student)
      create(:team_member, team: defendant_team, user: defendant_student)
      
      create(:case_team, case: case_record, team: plaintiff_team, role: "plaintiff")
      create(:case_team, case: case_record, team: defendant_team, role: "defendant")
      
      create(:performance_score, simulation: simulation, team: plaintiff_team, 
             user: plaintiff_student, total_score: 85, legal_strategy_score: 28)
      create(:performance_score, simulation: simulation, team: defendant_team, 
             user: defendant_student, total_score: 80, legal_strategy_score: 25)

      get :class_analytics, format: :json

      json_response = JSON.parse(response.body)
      expect(json_response).to include("role_comparison")
      expect(json_response["role_comparison"]).to include(
        "plaintiff_average" => be_a(Numeric),
        "defendant_average" => be_a(Numeric),
        "statistical_significance" => be_a(Hash)
      )
    end

    context "when user is not an instructor" do
      before { sign_in student }

      it "returns forbidden status" do
        get :class_analytics, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #export_report" do
    before { sign_in student }

    it "generates and returns PDF performance report" do
      create(:performance_score, 
        simulation: simulation, 
        team: team, 
        user: student,
        total_score: 85,
        settlement_quality_score: 32,
        legal_strategy_score: 24,
        collaboration_score: 16,
        efficiency_score: 8
      )

      post :export_report, format: :pdf

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("performance_report")
    end

    it "includes comprehensive performance data in PDF" do
      create(:performance_score, 
        simulation: simulation, 
        team: team, 
        user: student,
        total_score: 85
      )

      allow(PerformanceReportGenerator).to receive(:new).and_call_original
      
      post :export_report, format: :pdf

      expect(response).to have_http_status(:success)
      expect(PerformanceReportGenerator).to have_received(:new).with(
        user: student,
        include_trends: true,
        include_recommendations: true
      )
    end
  end

  describe "PATCH #update_score" do
    context "when user is an instructor" do
      before { sign_in instructor }

      it "allows instructor to manually adjust scores" do
        performance_score = create(:performance_score, 
          simulation: simulation, 
          team: team, 
          user: student,
          total_score: 80,
          settlement_quality_score: 30
        )

        patch :update_score, params: {
          id: performance_score.id,
          performance_score: {
            instructor_adjustment: 5,
            adjustment_reason: "Exceptional teamwork not captured in metrics"
          }
        }, format: :json

        expect(response).to have_http_status(:success)
        performance_score.reload
        expect(performance_score.instructor_adjustment).to eq(5)
        expect(performance_score.adjustment_reason).to eq("Exceptional teamwork not captured in metrics")
      end

      it "validates adjustment reasons are provided" do
        performance_score = create(:performance_score, simulation: simulation, team: team, user: student)

        patch :update_score, params: {
          id: performance_score.id,
          performance_score: {
            instructor_adjustment: 10
          }
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("adjustment_reason")
      end
    end

    context "when user is a student" do
      before { sign_in student }

      it "returns forbidden status" do
        performance_score = create(:performance_score, simulation: simulation, team: team, user: student)

        patch :update_score, params: { id: performance_score.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end