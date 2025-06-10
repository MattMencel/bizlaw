# frozen_string_literal: true

class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course, only: [:show, :edit, :update, :destroy, :manage_invitations, :create_invitation]
  before_action :require_instructor_or_admin, except: [:index, :show]
  before_action :authorize_course_access, only: [:show, :edit, :update, :destroy, :manage_invitations, :create_invitation]
  before_action :check_course_creation_limit!, only: [:create]

  def index
    @courses = if current_user.instructor? || current_user.admin?
                current_user.taught_courses.includes(:students, :course_invitations).active
              else
                current_user.enrolled_courses.includes(:instructor).active
              end

    @courses = @courses.search_by_title(params[:search]) if params[:search].present?
  end

  def show
    @course_invitation = @course.course_invitations.active.first
    @students = @course.students.includes(:course_enrollments)
    @teams = @course.teams.includes(:team_members, :owner)
    @recent_enrollments = @course.course_enrollments.recent.limit(10).includes(:user)
  end

  def new
    @course = Course.new
    @course.year = Date.current.year
    @course.semester = infer_current_semester
  end

  def create
    @course = Course.new(course_params)
    @course.instructor = current_user

    if @course.save
      # Create a default invitation
      @course.course_invitations.create(
        name: "Default Invitation",
        expires_at: 1.month.from_now
      )

      redirect_to @course, notice: 'Course was successfully created with a default invitation code.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy
    redirect_to courses_path, notice: 'Course was successfully deleted.'
  end

  def manage_invitations
    @invitations = @course.course_invitations.includes(:course).order(created_at: :desc)
    @new_invitation = @course.course_invitations.build
  end

  def create_invitation
    @invitation = @course.course_invitations.build(invitation_params)

    if @invitation.save
      redirect_to manage_invitations_course_path(@course),
                  notice: "Invitation '#{@invitation.display_name}' was created successfully."
    else
      @invitations = @course.course_invitations.includes(:course).order(created_at: :desc)
      @new_invitation = @invitation
      render :manage_invitations, status: :unprocessable_entity
    end
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:title, :description, :course_code, :semester, :year, :start_date, :end_date, :active)
  end

  def invitation_params
    params.require(:course_invitation).permit(:name, :expires_at, :max_uses)
  end

  def require_instructor_or_admin
    unless current_user.instructor? || current_user.admin?
      redirect_to courses_path, alert: "You are not authorized to manage courses."
    end
  end

  def authorize_course_access
    return if current_user.admin?
    return if @course.instructor == current_user
    return if current_user.student? && @course.enrolled?(current_user) && action_name == 'show'

    redirect_to courses_path, alert: "You are not authorized to access this course."
  end

  def infer_current_semester
    case Date.current.month
    when 1..5
      "Spring"
    when 6..8
      "Summer"
    when 9..12
      "Fall"
    end
  end
end
