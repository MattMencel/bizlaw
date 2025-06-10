# frozen_string_literal: true

class TeamsController < ApplicationController
  include ImpersonationReadOnly

  before_action :set_team, only: [ :show, :edit, :update, :destroy ]

  def index
    @teams = Team.includes(:team_members).all

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
    @team = Team.new
  end

  def edit
  end

  def create
    @team = Team.new(team_params)

    respond_to do |format|
      if @team.save
        format.html { redirect_to team_path(@team), notice: "Team was successfully created." }
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
    @team.destroy

    respond_to do |format|
      format.html { redirect_to teams_path, notice: "Team was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :description)
  end
end
