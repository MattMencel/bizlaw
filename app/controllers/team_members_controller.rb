# frozen_string_literal: true

class TeamMembersController < ApplicationController
  include ImpersonationReadOnly
  
  before_action :set_team
  before_action :set_team_member, only: [:show, :edit, :update, :destroy]
  before_action :authorize_team_access!

  def index
    @team_members = @team.team_members.includes(:user)
    
    respond_to do |format|
      format.html
      format.json { render json: TeamMemberSerializer.new(@team_members).serializable_hash }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: TeamMemberSerializer.new(@team_member).serializable_hash }
    end
  end

  def new
    @team_member = @team.team_members.build
    @available_users = available_users_for_team
  end

  def create
    @team_member = @team.team_members.build(team_member_params)
    
    respond_to do |format|
      if @team_member.save
        format.html { redirect_to @team, notice: 'Team member was successfully added.' }
        format.json { render json: TeamMemberSerializer.new(@team_member).serializable_hash, status: :created }
      else
        @available_users = available_users_for_team
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @team_member.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @available_users = available_users_for_team
  end

  def update
    respond_to do |format|
      if @team_member.update(team_member_params)
        format.html { redirect_to @team, notice: 'Team member was successfully updated.' }
        format.json { render json: TeamMemberSerializer.new(@team_member).serializable_hash }
      else
        @available_users = available_users_for_team
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @team_member.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @team_member.destroy
    
    respond_to do |format|
      format.html { redirect_to @team, notice: 'Team member was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_team
    @team = Team.find(params[:team_id])
  end

  def set_team_member
    @team_member = @team.team_members.find(params[:id])
  end

  def team_member_params
    params.require(:team_member).permit(:user_id, :role)
  end

  def authorize_team_access!
    unless policy(@team).update?
      redirect_to @team, alert: 'You do not have permission to manage team members.'
    end
  end

  def available_users_for_team
    return User.none unless @team.course
    
    # Get users enrolled in the course who are not already team members
    enrolled_user_ids = @team.course.students.pluck(:id)
    existing_member_ids = @team.team_members.pluck(:user_id)
    
    User.where(id: enrolled_user_ids - existing_member_ids)
        .order(:last_name, :first_name)
  end
end