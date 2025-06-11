# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    case current_user.role
    when "admin"
      load_admin_data
      render "admin_dashboard"
    when "instructor"
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
    @my_courses = current_user.taught_courses.includes(:students)
    @my_teams = Team.joins(:members).where(team_members: { user: current_user })
    # TODO: implement activity tracking
    @recent_activity = []
  end

  def load_student_data
    @my_teams = current_user.teams.includes(:cases)
    @my_cases = current_user.cases.includes(:documents)
    # TODO: implement activity tracking
    @recent_activity = []
  end
end
