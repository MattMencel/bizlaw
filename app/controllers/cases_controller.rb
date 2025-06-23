class CasesController < ApplicationController
  include ImpersonationReadOnly

  before_action :set_course, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_case, only: [:show, :edit, :update, :destroy]
  before_action :authorize_case, only: [:show, :edit, :update, :destroy]

  def index
    if params[:course_id]
      @course = Course.find(params[:course_id])
      @cases = @course.cases.page(params[:page])
    else
      @cases = Case.accessible_by(current_user).page(params[:page])
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: CaseSerializer.new(@case).serializable_hash }
    end
  end

  def new
    if params[:scenario_id].present?
      @case = CaseScenarioService.build_case_from_scenario(
        params[:scenario_id],
        course: @course,
        created_by: current_user
      )
      @teams = @course.teams
      @selected_scenario = CaseScenarioService.find(params[:scenario_id])
    else
      @scenarios = CaseScenarioService.all
      @case = @course.cases.build
      @teams = @course.teams
    end
  end

  def create
    @case = @course.cases.build(case_params)
    @case.created_by = current_user
    @case.updated_by = current_user

    respond_to do |format|
      if @case.save
        format.html { redirect_to course_case_path(@course, @case), notice: "Case was successfully created." }
        format.json { render json: CaseSerializer.new(@case).serializable_hash, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @case.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @teams = @course.teams
  end

  def update
    respond_to do |format|
      if @case.update(case_params.merge(updated_by: current_user))
        format.html { redirect_to course_case_path(@course, @case), notice: "Case was successfully updated." }
        format.json { render json: CaseSerializer.new(@case).serializable_hash }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @case.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @case.can_be_deleted?
      respond_to do |format|
        format.html do
          redirect_to course_cases_path(@course), alert: @case.deletion_error_message
        end
        format.json do
          render json: {error: @case.deletion_error_message}, status: :unprocessable_entity
        end
      end
      return
    end

    @case.destroy

    respond_to do |format|
      format.html { redirect_to course_cases_path(@course), notice: "Case was successfully deleted." }
      format.json { head :no_content }
    end
  end

  def background
    if params[:id]
      set_case
      authorize_case
    else
      @cases = Case.accessible_by(current_user).page(params[:page])
    end
  end

  def timeline
    if params[:id]
      set_case
      authorize_case
      @events = @case.case_events.order(:created_at)
    else
      @cases = Case.accessible_by(current_user).page(params[:page])
    end
  end

  def events
    if params[:id]
      set_case
      authorize_case
      @events = @case.case_events.order(:created_at)
    else
      @cases = Case.accessible_by(current_user).page(params[:page])
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id]) if params[:course_id]
  end

  def set_case
    if params[:course_id]
      @course = Course.find(params[:course_id])
      @case = @course.cases.find(params[:id])
    else
      @case = Case.find(params[:id])
    end
  end

  def case_params
    permitted_params = params.require(:case).permit(:title, :description, :case_type, :difficulty_level,
      :plaintiff_info, :defendant_info, :reference_number, :legal_issues, team_ids: [],
      legal_issues: [], plaintiff_info_keys: [], plaintiff_info_values: [],
      defendant_info_keys: [], defendant_info_values: [])

    # Convert key-value arrays to JSON if they exist
    if permitted_params[:plaintiff_info_keys].present? && permitted_params[:plaintiff_info_values].present?
      plaintiff_data = {}
      permitted_params[:plaintiff_info_keys].each_with_index do |key, index|
        next if key.blank?
        plaintiff_data[key] = permitted_params[:plaintiff_info_values][index] || ""
      end
      permitted_params[:plaintiff_info] = plaintiff_data
      permitted_params.delete(:plaintiff_info_keys)
      permitted_params.delete(:plaintiff_info_values)
    elsif permitted_params[:plaintiff_info_keys].present? || permitted_params[:plaintiff_info_values].present?
      # Handle case where keys/values exist but are empty or blank
      permitted_params[:plaintiff_info] = {}
      permitted_params.delete(:plaintiff_info_keys)
      permitted_params.delete(:plaintiff_info_values)
    end

    if permitted_params[:defendant_info_keys].present? && permitted_params[:defendant_info_values].present?
      defendant_data = {}
      permitted_params[:defendant_info_keys].each_with_index do |key, index|
        next if key.blank?
        defendant_data[key] = permitted_params[:defendant_info_values][index] || ""
      end
      permitted_params[:defendant_info] = defendant_data
      permitted_params.delete(:defendant_info_keys)
      permitted_params.delete(:defendant_info_values)
    elsif permitted_params[:defendant_info_keys].present? || permitted_params[:defendant_info_values].present?
      # Handle case where keys/values exist but are empty or blank
      permitted_params[:defendant_info] = {}
      permitted_params.delete(:defendant_info_keys)
      permitted_params.delete(:defendant_info_values)
    end

    # Convert legal_issues string to array if needed
    if permitted_params[:legal_issues].is_a?(String) && permitted_params[:legal_issues].present?
      # Split by commas and clean up whitespace
      permitted_params[:legal_issues] = permitted_params[:legal_issues].split(",").map(&:strip).compact_blank
    elsif permitted_params[:legal_issues].blank?
      permitted_params[:legal_issues] = []
    end

    permitted_params
  end

  def authorize_case
    authorize @case
  end
end
