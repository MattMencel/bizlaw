# frozen_string_literal: true

class TeamsController < ApplicationController
  include ImpersonationReadOnly

  before_action :set_course, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def index
    @teams = Team.accessible_by(current_user)
      .includes(:owner, :team_members, simulation: {case: :course})

    # Apply filters
    @teams = apply_filters(@teams)

    # Organize data based on view parameter
    case params[:view]
    when "hierarchical"
      @teams_by_course = @teams.group_by { |team| team.course }
    when "simulation"
      @teams_by_simulation = @teams.group_by { |team| team.simulation }
    else
      # Default flat view - no additional grouping needed
    end

    respond_to do |format|
      format.html
      format.html.turbo_stream
      format.json { render json: TeamSerializer.new(@teams).serializable_hash }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: TeamSerializer.new(@team).serializable_hash }
    end
  end

  def new
    @team = @course.teams.build
  end

  def edit
  end

  def create
    @team = @course.teams.build(team_params)
    @team.owner = current_user

    respond_to do |format|
      if @team.save
        format.html { redirect_to course_path(@course), notice: "Team was successfully created." }
        format.json { render json: TeamSerializer.new(@team).serializable_hash, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to team_path(@team), notice: "Team was successfully updated." }
        format.json { render json: TeamSerializer.new(@team).serializable_hash }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @team
    @team.destroy

    respond_to do |format|
      if @course
        format.html { redirect_to course_path(@course), notice: "Team was successfully deleted." }
      else
        format.html { redirect_to teams_path, notice: "Team was successfully deleted." }
      end
      format.json { head :no_content }
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id]) if params[:course_id]
  end

  def set_team
    @team = if @course
      @course.teams.accessible_by(current_user).find(params[:id])
    else
      Team.accessible_by(current_user).find(params[:id])
    end
  end

  def team_params
    params.require(:team).permit(:name, :description, :max_members)
  end

  def apply_filters(teams)
    # Filter by course
    if params[:course_id].present?
      teams = teams.joins(simulation: {case: :course})
        .where(cases: {course_id: params[:course_id]})
    end

    # Filter by role
    if params[:role].present?
      teams = teams.where(role: params[:role])
    end

    # Filter by simulation status
    if params[:simulation_status].present?
      teams = teams.joins(:simulation)
        .where(simulations: {status: params[:simulation_status]})
    end

    teams
  end
end
