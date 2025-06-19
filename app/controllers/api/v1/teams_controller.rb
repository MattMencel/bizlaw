# frozen_string_literal: true

module Api
  module V1
    class TeamsController < BaseController
      before_action :set_team, only: [:show, :update, :destroy]

      def index
        @teams = policy_scope(Team).includes(:owner, :team_members)
        @teams = @teams.search_by_name(params[:query]) if params[:query].present?
        @teams = @teams.page(params[:page]).per(params[:per_page])

        render json: TeamSerializer.new(@teams,
          include: [:owner],
          meta: pagination_meta(@teams)).serializable_hash
      end

      def show
        authorize @team
        render json: TeamSerializer.new(@team,
          include: [:owner, :team_members]).serializable_hash
      end

      def create
        @team = Team.new(team_params)
        @team.owner = current_user
        authorize @team

        if @team.save
          render json: TeamSerializer.new(@team).serializable_hash,
            status: :created
        else
          render json: {
            errors: @team.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @team
        if @team.update(team_params)
          render json: TeamSerializer.new(@team).serializable_hash
        else
          render json: {
            errors: @team.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @team
        @team.destroy
        head :no_content
      end

      private

      def set_team
        @team = Team.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {error: "Team not found"}, status: :not_found
      end

      def team_params
        params.require(:team).permit(:name, :description, :max_members)
      end

      def pagination_meta(teams)
        {
          current_page: teams.current_page,
          total_pages: teams.total_pages,
          total_count: teams.total_count
        }
      end
    end
  end
end
