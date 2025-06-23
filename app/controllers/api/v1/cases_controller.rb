# frozen_string_literal: true

module Api
  module V1
    # Cases API controller handling CRUD operations for cases
    class CasesController < BaseController
      before_action :set_case, only: %i[show update destroy]

      def index
        @cases = policy_scope(Case).includes(:team, :created_by, :case_teams, :assigned_teams)
        @cases = filter_cases(@cases)
        render_cases_with_includes(@cases)
      end

      def show
        authorize @case
        render json: CaseSerializer.new(
          @case,
          include: %i[team created_by updated_by case_teams assigned_teams documents case_events]
        ).serializable_hash
      end

      def create
        @case = build_case
        authorize @case
        if @case.save
          render_case_with_includes(@case, :created)
        else
          render_errors(@case.errors)
        end
      end

      def update
        authorize @case
        if @case.update(case_params.merge(updated_by: current_user))
          render_case_with_includes(@case)
        else
          render_errors(@case.errors)
        end
      end

      def destroy
        authorize @case

        unless @case.can_be_deleted?
          render json: {error: @case.deletion_error_message}, status: :unprocessable_entity
          return
        end

        @case.destroy
        head :no_content
      end

      private

      def filter_cases(cases)
        cases = cases.search_by_title(params[:query]) if params[:query].present?
        cases = cases.by_status(params[:status]) if params[:status].present?
        cases = cases.by_difficulty(params[:difficulty_level]) if params[:difficulty_level].present?
        cases = cases.by_type(params[:case_type]) if params[:case_type].present?
        cases.page(params[:page]).per(params[:per_page])
      end

      def build_case
        Case.new(case_params).tap do |kase|
          kase.created_by = current_user
          kase.updated_by = current_user
        end
      end

      def render_cases_with_includes(cases)
        render json: CaseSerializer.new(
          cases,
          include: %i[team created_by],
          meta: pagination_meta(cases)
        ).serializable_hash
      end

      def render_case_with_includes(kase, status = :ok)
        render json: CaseSerializer.new(
          kase,
          include: %i[team]
        ).serializable_hash, status: status
      end

      def render_errors(errors)
        render json: {
          errors: errors.full_messages
        }, status: :unprocessable_entity
      end

      def set_case
        @case = Case.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {error: "Case not found"}, status: :not_found
      end

      def case_params
        params.require(:case).permit(
          :title,
          :description,
          :reference_number,
          :status,
          :difficulty_level,
          :case_type,
          :due_date,
          :team_id,
          plaintiff_info: %i[name contact_details address],
          defendant_info: %i[name contact_details address],
          legal_issues: %i[issue_type description],
          case_teams_attributes: %i[id team_id role _destroy]
        )
      end

      def pagination_meta(cases)
        {
          current_page: cases.current_page,
          total_pages: cases.total_pages,
          total_count: cases.total_count
        }
      end
    end
  end
end
