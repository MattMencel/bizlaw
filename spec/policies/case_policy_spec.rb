# frozen_string_literal: true

require "rails_helper"

RSpec.describe CasePolicy, type: :policy do
  let(:admin) { build_stubbed(:user, role: :admin) }
  let(:instructor) { build_stubbed(:user, role: :instructor) }
  let(:student) { build_stubbed(:user, role: :student) }
  let(:other_student) { build_stubbed(:user, role: :student) }

  let(:case_record) { build_stubbed(:case, created_by_id: instructor.id) }
  let(:team) { build_stubbed(:team) }

  before do
    allow(student).to receive_messages(teams: double(joins: double(exists?: true)), team_ids: [team.id])
    allow(other_student).to receive_messages(teams: double(joins: double(exists?: false)), team_ids: [])
  end

  describe "#index?" do
    it "permits access for all users" do
      policy = described_class.new(admin, case_record)
      expect(policy.index?).to be true

      policy = described_class.new(instructor, case_record)
      expect(policy.index?).to be true

      policy = described_class.new(student, case_record)
      expect(policy.index?).to be true
    end
  end

  describe "#show?" do
    it "permits admin access" do
      policy = described_class.new(admin, case_record)
      expect(policy.show?).to be true
    end

    it "permits instructor access" do
      policy = described_class.new(instructor, case_record)
      expect(policy.show?).to be true
    end

    it "permits creator access" do
      policy = described_class.new(instructor, case_record)
      expect(policy.show?).to be true
    end

    it "permits student access when on assigned team" do
      policy = described_class.new(student, case_record)
      expect(policy.show?).to be true
    end

    it "denies student access when not on assigned team" do
      policy = described_class.new(other_student, case_record)
      expect(policy.show?).to be false
    end
  end

  describe "#create?" do
    # NOTE: role predicates read the `roles` array column, so these use the
    # factory traits rather than `role:` like the older examples above.
    let(:course_owner) { build_stubbed(:user, :instructor) }
    let(:other_instructor) { build_stubbed(:user, :instructor) }
    let(:site_admin) { build_stubbed(:user, :admin) }
    let(:enrolled_student) { build_stubbed(:user, :student) }
    let(:own_course) { build_stubbed(:course, instructor: course_owner) }
    let(:other_course) { build_stubbed(:course, instructor: other_instructor) }

    it "permits admin to create cases" do
      policy = described_class.new(site_admin, Case.new(course: own_course))
      expect(policy.create?).to be true
    end

    it "permits admin to create cases without a course" do
      policy = described_class.new(site_admin, Case.new)
      expect(policy.create?).to be true
    end

    it "permits instructor to create cases in their own course" do
      policy = described_class.new(course_owner, Case.new(course: own_course))
      expect(policy.create?).to be true
    end

    it "denies instructor creating cases in another instructor's course" do
      policy = described_class.new(course_owner, Case.new(course: other_course))
      expect(policy.create?).to be false
    end

    it "denies instructor creating cases with no course" do
      policy = described_class.new(course_owner, Case.new)
      expect(policy.create?).to be false
    end

    it "denies student access to create cases" do
      policy = described_class.new(enrolled_student, Case.new(course: own_course))
      expect(policy.create?).to be false
    end

    describe "#new?" do
      it "mirrors #create?" do
        expect(described_class.new(course_owner, Case.new(course: own_course)).new?).to be true
        expect(described_class.new(course_owner, Case.new(course: other_course)).new?).to be false
      end
    end
  end

  describe "#update?" do
    it "permits admin access" do
      policy = described_class.new(admin, case_record)
      expect(policy.update?).to be true
    end

    it "permits creator access" do
      policy = described_class.new(instructor, case_record)
      expect(policy.update?).to be true
    end

    it "permits instructor access" do
      other_instructor = build_stubbed(:user, role: :instructor)
      policy = described_class.new(other_instructor, case_record)
      expect(policy.update?).to be true
    end

    it "denies student access" do
      policy = described_class.new(student, case_record)
      expect(policy.update?).to be false
    end
  end

  describe "#destroy?" do
    it "permits admin access" do
      policy = described_class.new(admin, case_record)
      expect(policy.destroy?).to be true
    end

    it "permits creator access" do
      policy = described_class.new(instructor, case_record)
      expect(policy.destroy?).to be true
    end

    it "permits instructor access" do
      other_instructor = build_stubbed(:user, role: :instructor)
      policy = described_class.new(other_instructor, case_record)
      expect(policy.destroy?).to be true
    end

    it "denies student access" do
      policy = described_class.new(student, case_record)
      expect(policy.destroy?).to be false
    end
  end

  describe CasePolicy::Scope do
    let(:scope) { Case }
    let(:policy_scope) { CasePolicy::Scope.new(user, scope) }

    context "when user is admin" do
      let(:user) { admin }

      it "returns all cases" do
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context "when user is instructor" do
      let(:user) { instructor }

      it "returns all cases" do
        expect(scope).to receive(:all)
        policy_scope.resolve
      end
    end

    context "when user is student" do
      let(:user) { student }

      it "returns only cases for assigned teams" do
        assigned_teams_scope = double("assigned_teams_scope")
        expect(scope).to receive(:joins).with(:assigned_teams).and_return(assigned_teams_scope)
        expect(assigned_teams_scope).to receive(:where).with(teams: {id: user.team_ids})

        policy_scope.resolve
      end
    end

    context "when user has no role" do
      let(:user) { build_stubbed(:user, role: nil) }

      it "returns no cases" do
        expect(scope).to receive(:none)
        policy_scope.resolve
      end
    end
  end
end
