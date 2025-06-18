# frozen_string_literal: true

class ScoringDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_simulation, only: [ :index, :performance_data, :trends ]
  before_action :authorize_instructor, only: [ :class_analytics, :update_score ]

  def index
    case current_user.role
    when "instructor", "admin"
      load_instructor_dashboard_data
      render "instructor_index"
    else
      load_student_dashboard_data
      render "student_index"
    end
  end

  def performance_data
    respond_to do |format|
      format.json do
        data = {
          total_score: @current_simulation_score&.total_score || 0,
          grade: @current_simulation_score&.performance_grade || "Not Yet Scored",
          breakdown: @current_simulation_score&.score_breakdown || {},
          strengths: @current_simulation_score&.identify_strengths || [],
          improvement_areas: @current_simulation_score&.identify_improvement_areas || [],
          rank: @current_simulation_score&.rank_in_simulation,
          percentile: @current_simulation_score&.percentile_in_simulation
        }

        if params[:include_team].present? && @current_simulation_score
          data[:team_comparison] = build_team_comparison_data
        end

        render json: data
      end
    end
  end

  def trends
    respond_to do |format|
      format.json do
        trend_data = build_trend_data
        improvement_analysis = calculate_improvement_analysis(trend_data)

        render json: {
          trend_data: trend_data,
          improvement_analysis: improvement_analysis
        }
      end
    end
  end

  def class_analytics
    respond_to do |format|
      format.json do
        analytics_data = build_class_analytics_data
        render json: analytics_data
      end
    end
  end

  def export_report
    respond_to do |format|
      format.pdf do
        report_generator = PerformanceReportGenerator.new(
          user: current_user,
          include_trends: true,
          include_recommendations: true
        )

        pdf_data = report_generator.generate_pdf

        send_data pdf_data,
                  filename: "performance_report_#{current_user.id}_#{Date.current.strftime('%Y%m%d')}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  def update_score
    @performance_score = PerformanceScore.find(params[:id])

    respond_to do |format|
      format.json do
        if update_score_params[:adjustment_reason].blank?
          render json: { errors: { adjustment_reason: [ "is required for manual adjustments" ] } },
                 status: :unprocessable_entity
          return
        end

        if @performance_score.update(update_score_params.merge(
          adjusted_by: current_user,
          adjusted_at: Time.current
        ))
          render json: {
            success: true,
            new_total: @performance_score.total_score,
            message: "Score updated successfully"
          }
        else
          render json: { errors: @performance_score.errors }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_current_simulation
    # Find the user's current active simulation
    @current_simulation = current_user.teams
                                     .joins(case_teams: { case: :simulation })
                                     .merge(Simulation.active)
                                     .first&.case&.simulation

    if @current_simulation
      user_team = current_user.teams.joins(:case_teams)
                             .where(case_teams: { case: @current_simulation.case })
                             .first

      @current_simulation_score = PerformanceScore.find_by(
        simulation: @current_simulation,
        team: user_team,
        user: current_user,
        score_type: "individual"
      )
    end
  end

  def load_student_dashboard_data
    @my_scores = current_user.performance_scores
                            .includes(:simulation, :team)
                            .order(scored_at: :desc)
                            .limit(10)

    @performance_summary = build_performance_summary
    @performance_trends = build_student_trend_data
    @recent_achievements = build_recent_achievements
    @team_standing = build_team_standing_data
  end

  def load_instructor_dashboard_data
    # Get all simulations for courses the instructor teaches
    @instructor_simulations = Simulation.joins(case: :course)
                                       .where(cases: { courses: { id: instructor_course_ids } })

    # Filter by specific simulation if requested
    if params[:simulation_id].present?
      @filtered_simulation = @instructor_simulations.find(params[:simulation_id])
      simulation_filter = @filtered_simulation
    else
      simulation_filter = @instructor_simulations
    end

    @class_performance_data = build_class_performance_data(simulation_filter)
    @class_averages = calculate_class_averages(simulation_filter)
    @students_needing_help = identify_students_needing_help(simulation_filter)
    @top_performers = identify_top_performers(simulation_filter)
  end

  def build_performance_summary
    return default_performance_summary unless @current_simulation_score

    {
      total_score: @current_simulation_score.total_score,
      grade: @current_simulation_score.performance_grade,
      percentile: @current_simulation_score.percentile_in_simulation,
      rank: @current_simulation_score.rank_in_simulation,
      simulation_name: @current_simulation&.case&.title,
      last_updated: @current_simulation_score.scored_at
    }
  end

  def default_performance_summary
    {
      total_score: 0,
      grade: "Not Yet Scored",
      percentile: nil,
      rank: nil,
      simulation_name: "No Active Simulation",
      last_updated: nil
    }
  end

  def build_student_trend_data
    return [] unless @current_simulation

    user_team = current_user.teams.joins(:case_teams)
                           .where(case_teams: { case: @current_simulation.case })
                           .first

    PerformanceScore.where(
      simulation: @current_simulation,
      team: user_team,
      user: current_user
    ).order(:scored_at)
     .limit(20)
     .pluck(:scored_at, :total_score, :settlement_quality_score, :legal_strategy_score, :collaboration_score)
  end

  def build_recent_achievements
    return [] unless @current_simulation_score

    achievements = []

    if @current_simulation_score.speed_bonus > 0
      achievements << {
        type: "speed_bonus",
        title: "Speed Bonus",
        description: "Earned #{@current_simulation_score.speed_bonus} points for efficient negotiation",
        points: @current_simulation_score.speed_bonus,
        earned_at: @current_simulation_score.scored_at
      }
    end

    if @current_simulation_score.creative_terms_score > 0
      achievements << {
        type: "creative_terms",
        title: "Creative Solution",
        description: "Earned #{@current_simulation_score.creative_terms_score} points for innovative terms",
        points: @current_simulation_score.creative_terms_score,
        earned_at: @current_simulation_score.scored_at
      }
    end

    achievements
  end

  def build_team_standing_data
    return {} unless @current_simulation && @current_simulation_score

    user_team = current_user.teams.joins(:case_teams)
                           .where(case_teams: { case: @current_simulation.case })
                           .first

    team_score = PerformanceScore.find_by(
      simulation: @current_simulation,
      team: user_team,
      score_type: "team"
    )

    return {} unless team_score

    all_team_scores = PerformanceScore.where(
      simulation: @current_simulation,
      score_type: "team"
    ).order(total_score: :desc)

    {
      team_score: team_score.total_score,
      team_rank: all_team_scores.index(team_score) + 1,
      total_teams: all_team_scores.count,
      team_percentile: ((all_team_scores.count - all_team_scores.index(team_score)).to_f / all_team_scores.count * 100).round(1)
    }
  end

  def build_team_comparison_data
    user_team = current_user.teams.joins(:case_teams)
                           .where(case_teams: { case: @current_simulation.case })
                           .first

    team_members = PerformanceScore.where(
      simulation: @current_simulation,
      team: user_team,
      score_type: "individual"
    )

    team_average = team_members.average(:total_score) || 0
    my_rank = team_members.where("total_score > ?", @current_simulation_score.total_score).count + 1

    {
      team_average: team_average.round(1),
      my_rank_in_team: my_rank,
      team_member_count: team_members.count
    }
  end

  def build_trend_data
    return [] unless @current_simulation

    user_team = current_user.teams.joins(:case_teams)
                           .where(case_teams: { case: @current_simulation.case })
                           .first

    PerformanceScore.where(
      simulation: @current_simulation,
      team: user_team,
      user: current_user
    ).order(:scored_at)
     .map do |score|
      {
        date: score.scored_at.strftime("%Y-%m-%d"),
        total_score: score.total_score,
        settlement_quality_score: score.settlement_quality_score || 0,
        legal_strategy_score: score.legal_strategy_score || 0,
        collaboration_score: score.collaboration_score || 0,
        efficiency_score: score.efficiency_score || 0
      }
    end
  end

  def calculate_improvement_analysis(trend_data)
    return { overall_trend: "no_data", total_improvement: 0 } if trend_data.length < 2

    first_score = trend_data.first[:total_score]
    last_score = trend_data.last[:total_score]
    total_improvement = last_score - first_score

    trend_direction = if total_improvement > 5
                       "improving"
    elsif total_improvement < -5
                       "declining"
    else
                       "stable"
    end

    {
      overall_trend: trend_direction,
      total_improvement: total_improvement,
      average_improvement_per_update: (total_improvement.to_f / (trend_data.length - 1)).round(2)
    }
  end

  def build_class_performance_data(simulations)
    PerformanceScore.joins(:user, :simulation)
                   .where(simulation: simulations, score_type: "individual")
                   .includes(:user, :team, simulation: :case)
                   .order(:total_score)
                   .map do |score|
      {
        user_id: score.user.id,
        user_name: "#{score.user.first_name} #{score.user.last_name}",
        team_name: score.team.name,
        simulation_name: score.simulation.case.title,
        total_score: score.total_score,
        grade: score.performance_grade,
        last_updated: score.scored_at,
        needs_help: score.total_score < 60
      }
    end
  end

  def calculate_class_averages(simulations)
    scores = PerformanceScore.where(simulation: simulations, score_type: "individual")

    {
      total_score: scores.average(:total_score)&.round(1) || 0,
      settlement_quality: scores.average(:settlement_quality_score)&.round(1) || 0,
      legal_strategy: scores.average(:legal_strategy_score)&.round(1) || 0,
      collaboration: scores.average(:collaboration_score)&.round(1) || 0,
      efficiency: scores.average(:efficiency_score)&.round(1) || 0
    }
  end

  def identify_students_needing_help(simulations)
    PerformanceScore.joins(:user)
                   .where(simulation: simulations, score_type: "individual")
                   .where("total_score < ?", 60)
                   .includes(:user, :team)
                   .map do |score|
      {
        user_id: score.user.id,
        user_name: "#{score.user.first_name} #{score.user.last_name}",
        team_name: score.team.name,
        total_score: score.total_score,
        primary_weakness: score.identify_improvement_areas.first
      }
    end
  end

  def identify_top_performers(simulations)
    PerformanceScore.joins(:user)
                   .where(simulation: simulations, score_type: "individual")
                   .where("total_score >= ?", 85)
                   .order(total_score: :desc)
                   .limit(10)
                   .includes(:user, :team)
                   .map do |score|
      {
        user_id: score.user.id,
        user_name: "#{score.user.first_name} #{score.user.last_name}",
        team_name: score.team.name,
        total_score: score.total_score,
        grade: score.performance_grade
      }
    end
  end

  def build_class_analytics_data
    simulations = @instructor_simulations

    # Get all individual scores for the instructor's simulations
    all_scores = PerformanceScore.joins(:user, team: :case_teams)
                                .where(simulation: simulations, score_type: "individual")
                                .includes(:user, :team, simulation: :case)

    # Calculate basic statistics
    class_averages = calculate_class_averages(simulations)

    # Score distribution for histogram
    score_ranges = [ 0, 60, 70, 80, 90, 100 ]
    distribution = score_ranges.each_cons(2).map do |min, max|
      count = all_scores.where(total_score: min...max).count
      { range: "#{min}-#{max-1}", count: count }
    end

    # Role comparison (plaintiff vs defendant)
    role_comparison = calculate_role_comparison(all_scores)

    # Top performers and students needing help
    top_performers = identify_top_performers(simulations)
    students_needing_help = identify_students_needing_help(simulations)

    {
      class_averages: class_averages,
      distribution: distribution,
      role_comparison: role_comparison,
      top_performers: top_performers,
      students_needing_help: students_needing_help,
      total_students: all_scores.count,
      completion_rate: calculate_completion_rate(simulations)
    }
  end

  def calculate_role_comparison(scores)
    plaintiff_scores = scores.joins(team: :case_teams)
                            .where(case_teams: { role: "plaintiff" })

    defendant_scores = scores.joins(team: :case_teams)
                            .where(case_teams: { role: "defendant" })

    plaintiff_avg = plaintiff_scores.average(:total_score)&.round(1) || 0
    defendant_avg = defendant_scores.average(:total_score)&.round(1) || 0

    # Simple statistical significance check (you could use a more sophisticated test)
    difference = (plaintiff_avg - defendant_avg).abs
    significance = difference > 5 ? "significant" : "not_significant"

    {
      plaintiff_average: plaintiff_avg,
      defendant_average: defendant_avg,
      difference: (plaintiff_avg - defendant_avg).round(1),
      statistical_significance: {
        is_significant: significance == "significant",
        description: significance == "significant" ?
          "The difference between plaintiff and defendant performance is statistically notable" :
          "No significant difference between plaintiff and defendant performance"
      }
    }
  end

  def calculate_completion_rate(simulations)
    total_expected_scores = User.joins(teams: { case_teams: :case })
                               .where(cases: { id: simulations.joins(:case).select("cases.id") })
                               .distinct
                               .count

    actual_scores = PerformanceScore.where(simulation: simulations, score_type: "individual").count

    return 0 if total_expected_scores.zero?

    ((actual_scores.to_f / total_expected_scores) * 100).round(1)
  end

  def instructor_course_ids
    case current_user.role
    when "admin"
      Course.all.pluck(:id)
    when "instructor"
      current_user.taught_courses.pluck(:id)
    else
      []
    end
  end

  def authorize_instructor
    unless current_user.instructor? || current_user.admin?
      respond_to do |format|
        format.json { render json: { error: "Access denied" }, status: :forbidden }
        format.html { redirect_to root_path, alert: "Access denied" }
      end
    end
  end

  def update_score_params
    params.require(:performance_score).permit(:instructor_adjustment, :adjustment_reason)
  end
end
