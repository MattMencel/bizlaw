# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMembersController, type: :controller do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:team) { create(:team, course: course, owner: instructor) }
  let(:student1) { create(:user, organization: organization) }
  let(:student2) { create(:user, organization: organization) }
  let(:student3) { create(:user, organization: organization) }

  before do
    # Enroll students in course
    create(:course_enrollment, user: student1, course: course, status: "active")
    create(:course_enrollment, user: student2, course: course, status: "active")
    create(:course_enrollment, user: student3, course: course, status: "active")

    sign_in instructor
  end

  describe "GET #index" do
    let!(:team_member) { create(:team_member, team: team, user: student1) }

    it "returns a success response" do
      get :index, params: {team_id: team.id}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { {user_id: student1.id, role: "member"} }

    it "creates a new team member" do
      expect {
        post :create, params: {team_id: team.id, team_member: valid_attributes}
      }.to change(TeamMember, :count).by(1)
    end

    it "responds with turbo stream on successful creation" do
      post :create, params: {team_id: team.id, team_member: valid_attributes}
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end

  describe "POST #bulk_create" do
    context "with valid user_ids" do
      let(:user_ids) { [student1.id, student2.id] }
      let(:params) { {team_id: team.id, user_ids: user_ids, role: "member"} }

      it "creates multiple team members" do
        expect {
          post :bulk_create, params: params
        }.to change(TeamMember, :count).by(2)
      end

      it "assigns the correct role to all members" do
        post :bulk_create, params: params.merge(role: "manager")

        team.reload
        expect(team.team_members.where(role: "manager").count).to eq(2)
      end

      it "responds with turbo stream format" do
        post :bulk_create, params: params
        expect(response.media_type).to eq Mime[:turbo_stream]
      end

      it "sets a success flash message" do
        post :bulk_create, params: params
        expect(flash[:notice]).to match(/Successfully added 2 team members/)
      end
    end

    context "with empty user_ids" do
      let(:params) { {team_id: team.id, user_ids: [], role: "member"} }

      it "does not create any team members" do
        expect {
          post :bulk_create, params: params
        }.not_to change(TeamMember, :count)
      end

      it "sets an error message" do
        post :bulk_create, params: params
        expect(flash[:error]).to eq("Please select at least one student.")
      end

      it "renders the new template with errors" do
        post :bulk_create, params: params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end

    context "with some invalid user_ids" do
      let!(:existing_member) { create(:team_member, team: team, user: student1) }
      let(:user_ids) { [student1.id, student2.id] }
      let(:params) { {team_id: team.id, user_ids: user_ids, role: "member"} }

      it "creates valid members and reports errors for invalid ones" do
        expect {
          post :bulk_create, params: params
        }.to change(TeamMember, :count).by(1) # Only student2 gets added
      end

      it "includes error details in flash message" do
        post :bulk_create, params: params
        expect(flash[:error]).to include("Some members could not be added")
        expect(flash[:error]).to include(student1.full_name)
      end
    end
  end

  describe "PATCH #bulk_update" do
    let!(:member1) { create(:team_member, team: team, user: student1) }
    let!(:member2) { create(:team_member, team: team, user: student2) }
    let!(:member3) { create(:team_member, team: team, user: student3) }

    context "removing members" do
      let(:member_ids) { [member1.id, member2.id] }
      let(:params) { {team_id: team.id, member_ids: member_ids, action: "remove"} }

      it "removes the specified team members" do
        expect {
          patch :bulk_update, params: params
        }.to change(TeamMember, :count).by(-2)
      end

      it "only removes the specified members" do
        patch :bulk_update, params: params
        expect(TeamMember.find_by(id: member1.id)).to be_nil
        expect(TeamMember.find_by(id: member2.id)).to be_nil
        expect(TeamMember.find_by(id: member3.id)).to be_present
      end

      it "redirects with success message" do
        patch :bulk_update, params: params
        expect(response).to redirect_to(team)
        expect(flash[:notice]).to match(/Successfully removed 2 team members/)
      end
    end

    context "with empty member_ids" do
      let(:params) { {team_id: team.id, member_ids: [], action: "remove"} }

      it "does not remove any members" do
        expect {
          patch :bulk_update, params: params
        }.not_to change(TeamMember, :count)
      end

      it "redirects with error message" do
        patch :bulk_update, params: params
        expect(response).to redirect_to(team)
        expect(flash[:alert]).to eq("Please select at least one team member.")
      end
    end

    context "with invalid action" do
      let(:params) { {team_id: team.id, member_ids: [member1.id], action: "invalid"} }

      it "redirects with error message" do
        patch :bulk_update, params: params
        expect(response).to redirect_to(team)
        expect(flash[:alert]).to eq("Invalid action.")
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:team_member) { create(:team_member, team: team, user: student1) }

    it "destroys the team member" do
      expect {
        delete :destroy, params: {team_id: team.id, id: team_member.id}
      }.to change(TeamMember, :count).by(-1)
    end

    it "responds with turbo stream format" do
      delete :destroy, params: {team_id: team.id, id: team_member.id}
      expect(response.media_type).to eq Mime[:turbo_stream]
    end
  end

  describe "authorization" do
    let(:student) { create(:user, organization: organization) }

    before { sign_in student }

    it "prevents unauthorized users from managing team members" do
      post :create, params: {team_id: team.id, team_member: {user_id: student1.id}}
      expect(response).to redirect_to(team)
      expect(flash[:alert]).to match(/not have permission/)
    end

    it "prevents unauthorized bulk operations" do
      post :bulk_create, params: {team_id: team.id, user_ids: [student1.id]}
      expect(response).to redirect_to(team)
      expect(flash[:alert]).to match(/not have permission/)
    end
  end
end
