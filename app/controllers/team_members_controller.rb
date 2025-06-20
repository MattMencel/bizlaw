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
        format.turbo_stream {
          flash.now[:notice] = "Team member was successfully added."
          render turbo_stream: [
            turbo_stream.replace("new_team_member", ""),
            turbo_stream.update("team-members", partial: "teams/team_members", locals: {team: @team})
          ]
        }
        format.html { redirect_to @team, notice: "Team member was successfully added." }
        format.json { render json: TeamMemberSerializer.new(@team_member).serializable_hash, status: :created }
      else
        @available_users = available_users_for_team
        format.turbo_stream { render :new, status: :unprocessable_entity }
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
        format.html { redirect_to @team, notice: "Team member was successfully updated." }
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
      format.turbo_stream {
        flash.now[:notice] = "Team member was successfully removed."
        render turbo_stream: [
          turbo_stream.remove(dom_id(@team_member)),
          turbo_stream.update("team-members", partial: "teams/team_members", locals: {team: @team})
        ]
      }
      format.html { redirect_to @team, notice: "Team member was successfully removed." }
      format.json { head :no_content }
    end
  end

  def bulk_create
    user_ids = params[:user_ids]&.reject(&:blank?) || []
    role = params[:role] || "member"

    if user_ids.empty?
      flash[:error] = "Please select at least one student."
      @team_member = @team.team_members.build
      @available_users = available_users_for_team
      render :new, status: :unprocessable_entity
      return
    end

    created_count = 0
    errors = []

    user_ids.each do |user_id|
      team_member = @team.team_members.build(user_id: user_id, role: role)
      if team_member.save
        created_count += 1
      else
        user = User.find(user_id)
        errors << "#{user.full_name}: #{team_member.errors.full_messages.join(", ")}"
      end
    end

    respond_to do |format|
      if errors.empty?
        format.turbo_stream {
          flash.now[:notice] = "Successfully added #{created_count} team member#{"s" if created_count != 1}."
          render turbo_stream: [
            turbo_stream.replace("new_team_member", ""),
            turbo_stream.update("team-members", partial: "teams/team_members", locals: {team: @team})
          ]
        }
        format.html { redirect_to @team, notice: "Successfully added #{created_count} team member#{"s" if created_count != 1}." }
      else
        flash[:error] = "Some members could not be added: #{errors.join("; ")}"
        @team_member = @team.team_members.build
        @available_users = available_users_for_team
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def bulk_update
    action = params[:action_type] || params[:action]
    member_ids = params[:member_ids]&.reject(&:blank?) || []

    if member_ids.empty?
      redirect_to @team, alert: "Please select at least one team member."
      return
    end

    case action
    when "remove"
      team_members = @team.team_members.where(id: member_ids)
      removed_count = team_members.count
      team_members.destroy_all

      redirect_to @team, notice: "Successfully removed #{removed_count} team member#{"s" if removed_count != 1}."
    else
      redirect_to @team, alert: "Invalid action."
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
      redirect_to @team, alert: "You do not have permission to manage team members."
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
