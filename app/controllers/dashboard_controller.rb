# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.admin?
      load_admin_data
      render "admin_dashboard"
    elsif current_user.instructor?
      load_instructor_data
      render "instructor_dashboard"
    else
      load_student_data
      render "student_dashboard"
    end
  end

  private

  def load_admin_data
    @total_users = User.count
    @total_instructors = User.instructors.count
    @total_students = User.students.count
    @total_organizations = Organization.count
    @active_organizations = Organization.active.count
    @recent_users = User.order(created_at: :desc).limit(5)

    # Handle user search for impersonation
    if params[:user_search].present?
      @search_results = User.where(
        "LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query OR LOWER(email) LIKE :query",
        query: "%#{params[:user_search].downcase}%"
      ).where.not(id: current_user.id).limit(10)
    end
  end

  def load_instructor_data
    @my_courses = current_user.taught_courses
    @my_teams = Team.joins(:members).where(team_members: {user: current_user})
    # TODO: implement activity tracking
    @recent_activity = []
  end

  def load_student_data
    @my_teams = current_user.teams.includes(cases: [:simulations, :documents])
    @my_cases = current_user.cases.includes(:documents, :simulations)

    # Simulation-specific data for dashboard
    user_case_ids = current_user.cases.pluck(:id)

    @active_simulations = Simulation
      .where(case_id: user_case_ids, status: [:active, :paused])
      .includes(:case)

    @completed_simulations = Simulation
      .where(case_id: user_case_ids, status: [:completed, :arbitration])
      .includes(:case)

    @pending_simulations = Simulation
      .where(case_id: user_case_ids, status: :setup)
      .includes(:case)

    # Calculate simulation statistics
    @simulation_stats = calculate_simulation_stats

    # TODO: implement activity tracking
    @recent_activity = []
  end

  def calculate_simulation_stats
    user_case_ids = current_user.cases.pluck(:id)

    total_simulations = Simulation.where(case_id: user_case_ids).count
    completed_count = Simulation
      .where(case_id: user_case_ids, status: [:completed, :arbitration])
      .count

    active_count = Simulation
      .where(case_id: user_case_ids, status: [:active, :paused])
      .count

    settlement_count = Simulation
      .where(case_id: user_case_ids, status: :completed)
      .count

    settlement_rate = (completed_count > 0) ? (settlement_count.to_f / completed_count * 100).round(1) : 0

    {
      total: total_simulations,
      active: active_count,
      completed: completed_count,
      settlement_rate: settlement_rate
    }
  end
end
