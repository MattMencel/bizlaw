# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Teams", type: :request do
  let(:user) { create(:user) }
  let(:team) { create(:team, owner: user) }
  let(:other_user) { create(:user) }
  let(:other_team) { create(:team, owner: other_user) }

  before { sign_in user }

  describe "GET /api/v1/teams" do
    before do
      team
      other_team
    end

    it "returns a list of teams accessible by the user" do
      get "/api/v1/teams"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"].length).to eq(1)
      expect(json["data"].first["attributes"]["name"]).to eq(team.name)
    end

    context "with search query" do
      let!(:searchable_team) { create(:team, owner: user, name: "Alpha Team") }

      it "returns teams matching the search query" do
        get "/api/v1/teams", params: {query: "Alpha"}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
        expect(json["data"].first["attributes"]["name"]).to eq("Alpha Team")
      end
    end

    context "with pagination" do
      before { create_list(:team, 5, owner: user) }

      it "returns paginated results" do
        get "/api/v1/teams", params: {page: 1, per_page: 2}
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(2)
        expect(json["meta"]["total_pages"]).to eq(3)
        expect(json["meta"]["total_count"]).to eq(6)
      end
    end
  end

  describe "GET /api/v1/teams/:id" do
    it "returns the requested team" do
      get "/api/v1/teams/#{team.id}"
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["name"]).to eq(team.name)
    end

    it "returns not found for non-existent team" do
      get "/api/v1/teams/non-existent-id"
      expect(response).to have_http_status(:not_found)
    end

    it "includes owner and team members in response" do
      member = create(:team_member, team: team)
      get "/api/v1/teams/#{team.id}"

      json = JSON.parse(response.body)
      expect(json["included"]).to include(
        a_hash_including("type" => "user", "id" => team.owner.id.to_s)
      )
      expect(json["included"]).to include(
        a_hash_including("type" => "team_member", "id" => member.id.to_s)
      )
    end
  end

  describe "POST /api/v1/teams" do
    let(:valid_attributes) do
      {
        team: {
          name: "New Team",
          description: "Team description",
          max_members: 5
        }
      }
    end

    it "creates a new team" do
      expect {
        post "/api/v1/teams", params: valid_attributes
      }.to change(Team, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["name"]).to eq("New Team")
    end

    it "returns validation errors for invalid attributes" do
      post "/api/v1/teams", params: {team: {name: ""}}
      expect(response).to have_http_status(:unprocessable_entity)

      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/teams/:id" do
    let(:update_attributes) do
      {
        team: {
          name: "Updated Team",
          description: "Updated description"
        }
      }
    end

    it "updates the team" do
      patch "/api/v1/teams/#{team.id}", params: update_attributes
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]["attributes"]["name"]).to eq("Updated Team")
    end

    it "returns forbidden for non-owner without manager role" do
      patch "/api/v1/teams/#{other_team.id}", params: update_attributes
      expect(response).to have_http_status(:forbidden)
    end

    it "allows team manager to update the team" do
      create(:team_member, team: other_team, user: user, role: :manager)
      patch "/api/v1/teams/#{other_team.id}", params: update_attributes
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/teams/:id" do
    it "deletes the team" do
      delete "/api/v1/teams/#{team.id}"
      expect(response).to have_http_status(:no_content)
      expect(Team.find_by(id: team.id)).to be_nil
    end

    it "returns forbidden for non-owner without manager role" do
      delete "/api/v1/teams/#{other_team.id}"
      expect(response).to have_http_status(:forbidden)
    end

    it "allows team manager to delete the team" do
      create(:team_member, team: other_team, user: user, role: :manager)
      delete "/api/v1/teams/#{other_team.id}"
      expect(response).to have_http_status(:no_content)
    end
  end
end
