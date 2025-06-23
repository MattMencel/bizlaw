# frozen_string_literal: true

class SimulationsController < ApplicationController
  include ImpersonationReadOnly

  before_action :set_case
  before_action :set_simulation, except: [:new, :create]
  before_action :authorize_simulation_management

  def new
    service = SimulationDefaultsService.new(@case)
    @simulation = service.build_simulation_with_defaults
    load_teams_for_assignment
  end

  def create
    service = SimulationDefaultsService.new(@case)

    # Check if using defaults or custom parameters
    if simulation_params[:use_case_defaults] == "true"
      @simulation = service.build_simulation_with_defaults
    elsif simulation_params[:use_randomized_defaults] == "true"
      @simulation = service.build_simulation_with_randomized_defaults
    else
      # Manual configuration - use provided parameters
      @simulation = @case.build_simulation(simulation_params.except(:use_case_defaults, :use_randomized_defaults))
      @simulation.status = :setup
      @simulation.current_round = 1
      @simulation.simulation_config = default_simulation_config.merge(simulation_params[:simulation_config] || {})

      # Ensure teams are set if not provided
      if @simulation.plaintiff_team_id.blank? || @simulation.defendant_team_id.blank?
        teams = service.default_teams
        @simulation.plaintiff_team = teams[:plaintiff_team] if @simulation.plaintiff_team_id.blank?
        @simulation.defendant_team = teams[:defendant_team] if @simulation.defendant_team_id.blank?
      end
    end

    respond_to do |format|
      if @simulation.save
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation created successfully. Configure teams and parameters before starting." }
        format.json { render json: {status: "created", simulation: @simulation}, status: :created }
      else
        load_teams_for_assignment
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_teams_for_assignment
  end

  def update
    respond_to do |format|
      if @simulation.update(simulation_params)
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation configuration updated successfully." }
        format.json { render json: {status: "updated", simulation: @simulation} }
      else
        load_teams_for_assignment
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  def start
    service = SimulationOrchestrationService.new(@simulation)

    begin
      result = service.start_simulation!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation started successfully! Initial round has been created." }
        format.json { render json: {status: "started", result: result} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to start simulation: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def pause
    unless @simulation.status_active?
      return redirect_to course_case_path(@case.course, @case), alert: "Can only pause active simulations."
    end

    service = SimulationOrchestrationService.new(@simulation)

    begin
      service.pause_simulation!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation paused. Teams cannot submit new offers until resumed." }
        format.json { render json: {status: "paused"} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to pause simulation: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def resume
    unless @simulation.status_paused?
      return redirect_to course_case_path(@case.course, @case), alert: "Can only resume paused simulations."
    end

    service = SimulationOrchestrationService.new(@simulation)

    begin
      service.resume_simulation!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation resumed. Teams can now continue negotiations." }
        format.json { render json: {status: "resumed"} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to resume simulation: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def complete
    unless @simulation.status_active? || @simulation.status_paused?
      return redirect_to course_case_path(@case.course, @case), alert: "Can only complete active or paused simulations."
    end

    service = SimulationOrchestrationService.new(@simulation)

    begin
      service.complete_simulation!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Simulation completed successfully. Final results are now available." }
        format.json { render json: {status: "completed"} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to complete simulation: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def trigger_arbitration
    unless @simulation.status_active? || @simulation.status_paused?
      return redirect_to course_case_path(@case.course, @case), alert: "Can only trigger arbitration on active or paused simulations."
    end

    service = SimulationOrchestrationService.new(@simulation)

    begin
      service.trigger_arbitration!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Arbitration triggered. The simulation has been concluded with an arbitrated outcome." }
        format.json { render json: {status: "arbitration"} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to trigger arbitration: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def advance_round
    unless @simulation.status_active?
      return redirect_to course_case_path(@case.course, @case), alert: "Can only advance rounds on active simulations."
    end

    service = SimulationOrchestrationService.new(@simulation)

    begin
      service.advance_round!

      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), notice: "Advanced to round #{@simulation.reload.current_round}. New round is now active." }
        format.json { render json: {status: "advanced", current_round: @simulation.reload.current_round} }
      end
    rescue => e
      respond_to do |format|
        format.html { redirect_to course_case_path(@case.course, @case), alert: "Failed to advance round: #{e.message}" }
        format.json { render json: {error: e.message}, status: :unprocessable_entity }
      end
    end
  end

  def status
    render json: {
      simulation: {
        id: @simulation.id,
        status: @simulation.status,
        current_round: @simulation.current_round,
        total_rounds: @simulation.total_rounds,
        start_date: @simulation.start_date,
        end_date: @simulation.end_date,
        can_start: can_start_simulation?,
        can_pause: @simulation.status_active?,
        can_resume: @simulation.status_paused?,
        can_complete: @simulation.status_active? || @simulation.status_paused?,
        validation_errors: validation_errors
      }
    }
  end

  private

  def set_case
    if params[:course_id]
      @course = Course.find(params[:course_id])
      @case = @course.cases.find(params[:case_id])
    else
      @case = Case.find(params[:case_id])
      @course = @case.course
    end
  end

  def set_simulation
    @simulation = if params[:id]
      @case.simulations.find(params[:id])
    else
      @case.active_simulation
    end

    unless @simulation
      redirect_to course_case_path(@case.course, @case), alert: "No simulation exists for this case. Please create one first."
    end
  end

  def simulation_params
    params.require(:simulation).permit(
      :plaintiff_min_acceptable, :plaintiff_ideal,
      :defendant_ideal, :defendant_max_acceptable,
      :total_rounds, :pressure_escalation_rate,
      :plaintiff_team_id, :defendant_team_id,
      :use_case_defaults, :use_randomized_defaults,
      simulation_config: {}
    )
  end

  def authorize_simulation_management
    authorize @case, :manage_simulation?
  end

  def load_teams_for_assignment
    @available_teams = @case.course.teams
    @assigned_teams = @case.case_teams.includes(:team)
  end

  def default_simulation_config
    {
      "client_mood_enabled" => "true",
      "pressure_escalation_enabled" => "true",
      "auto_round_advancement" => "false",
      "settlement_range_hints" => "false",
      "arbitration_threshold_rounds" => "5",
      "round_duration_hours" => "48"
    }
  end

  def can_start_simulation?
    return false unless @simulation&.status_setup?

    validation_errors.empty?
  end

  def validation_errors
    service = SimulationOrchestrationService.new(@simulation)
    service.send(:validate_simulation_readiness)
  rescue
    ["Simulation validation failed"]
  end
end
