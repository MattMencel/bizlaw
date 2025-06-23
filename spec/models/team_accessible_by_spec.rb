# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team, ".accessible_by scope", type: :model do
  describe ".accessible_by" do
    let(:student) { create(:user, :student) }
    let(:instructor) { create(:user, :instructor) }
    let(:admin) { create(:user, :admin) }
    let(:course) { create(:course, instructor: instructor) }

    let!(:student_team) do
      # Enroll student in course first
      create(:course_enrollment, user: student, course: course, status: "active")
      create(:team, owner: student, course: course)
    end

    let!(:instructor_team) { create(:team, owner: instructor, course: course) }
    let!(:other_team) do
      other_owner = create(:user, :student)
      create(:course_enrollment, user: other_owner, course: course, status: "active")
      create(:team, owner: other_owner, course: course)
    end

    before do
      # Add student as member to their team
      create(:team_member, team: student_team, user: student)
      # Add student as member to one other team
      create(:team_member, team: instructor_team, user: student)
    end

    context "when user is a student" do
      it "returns only teams where the student is a member" do
        accessible_teams = described_class.accessible_by(student)
        expect(accessible_teams).to include(student_team, instructor_team)
        expect(accessible_teams).not_to include(other_team)
      end
    end

    context "when user is an instructor" do
      it "returns all teams" do
        accessible_teams = described_class.accessible_by(instructor)
        expect(accessible_teams).to include(student_team, instructor_team, other_team)
      end
    end

    context "when user is an admin" do
      it "returns all teams" do
        accessible_teams = described_class.accessible_by(admin)
        expect(accessible_teams).to include(student_team, instructor_team, other_team)
      end
    end
  end
end
