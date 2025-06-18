# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe "associations" do
    it { is_expected.to have_many(:team_members).dependent(:destroy) }
    it { is_expected.to have_many(:teams).through(:team_members) }
    it { is_expected.to have_many(:owned_teams).class_name("Team").with_foreign_key(:owner_id).dependent(:destroy) }
    it { is_expected.to have_many(:documents).with_foreign_key(:created_by_id) }
    it { is_expected.to have_many(:cases).through(:teams) }
    it { is_expected.to belong_to(:organization).optional.counter_cache(true) }
    it { is_expected.to have_many(:taught_courses).class_name("Course").with_foreign_key(:instructor_id).dependent(:destroy) }
    it { is_expected.to have_many(:course_enrollments).dependent(:destroy) }
    it { is_expected.to have_many(:enrolled_courses).through(:course_enrollments).source(:course) }
    it { is_expected.to have_many(:sent_invitations).class_name("Invitation").dependent(:destroy) }
  end

  # Validations
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:role) }

    describe "email format" do
      it "accepts valid email addresses" do
        valid_emails = [ "user@example.com", "USER@example.COM", "A_USER@example.com" ]
        valid_emails.each do |email|
          user.email = email
          expect(user).to be_valid
        end
      end

      it "rejects invalid email addresses" do
        invalid_emails = [ "user@example", "@example.com", "user@.com", "user@example." ]
        invalid_emails.each do |email|
          user.email = email
          expect(user).not_to be_valid
        end
      end
    end
  end

  # Enums
  describe "enums" do
    it "defines role enum with proper values" do
      expect(User.defined_enums["role"]).to eq({
        "student" => "student",
        "instructor" => "instructor",
        "admin" => "admin"
      })
    end

    it "provides role prefix methods" do
      user = build(:user, role: :student)
      expect(user).to respond_to(:role_student?)
      expect(user).to respond_to(:role_instructor?)
      expect(user).to respond_to(:role_admin?)
    end
  end

  # Scopes
  describe "scopes" do
    let!(:student) { create(:user, :student) }
    let!(:instructor) { create(:user, :instructor) }
    let!(:admin) { create(:user, :admin) }

    describe ".by_role" do
      it "returns users with specified role" do
        expect(described_class.by_role(:student)).to include(student)
        expect(described_class.by_role(:student)).not_to include(instructor, admin)
      end
    end

    describe ".instructors" do
      it "returns only instructors" do
        expect(described_class.instructors).to include(instructor)
        expect(described_class.instructors).not_to include(student, admin)
      end
    end

    describe ".students" do
      it "returns only students" do
        expect(described_class.students).to include(student)
        expect(described_class.students).not_to include(instructor, admin)
      end
    end

    describe ".admins" do
      it "returns only admins" do
        expect(described_class.admins).to include(admin)
        expect(described_class.admins).not_to include(student, instructor)
      end
    end

    describe ".search_by_name" do
      let!(:john_doe) { create(:user, first_name: "John", last_name: "Doe") }
      let!(:jane_doe) { create(:user, first_name: "Jane", last_name: "Doe") }

      it "finds users by partial first name match" do
        expect(described_class.search_by_name("jo")).to include(john_doe)
        expect(described_class.search_by_name("jo")).not_to include(jane_doe)
      end

      it "finds users by partial last name match" do
        expect(described_class.search_by_name("doe")).to include(john_doe, jane_doe)
      end

      it "is case insensitive" do
        expect(described_class.search_by_name("JOHN")).to include(john_doe)
      end
    end
  end

  # Instance methods
  describe "#full_name" do
    it "returns the full name" do
      user.first_name = "John"
      user.last_name = "Doe"
      expect(user.full_name).to eq("John Doe")
    end
  end

  describe "#display_name" do
    it "returns the full name" do
      user.first_name = "John"
      user.last_name = "Doe"
      expect(user.display_name).to eq("John Doe")
    end
  end

  describe "#active_for_authentication?" do
    it "returns true for active users" do
      expect(user.active_for_authentication?).to be true
    end

    it "returns false for deleted users" do
      user.soft_delete
      expect(user.active_for_authentication?).to be false
    end
  end

  describe "role predicates" do
    it "correctly identifies student role" do
      user.role = :student
      expect(user).to be_student
      expect(user).not_to be_instructor
      expect(user).not_to be_admin
    end

    it "correctly identifies instructor role" do
      user.role = :instructor
      user.roles = [ 'instructor' ]
      expect(user).to be_instructor
      expect(user).not_to be_student
      expect(user).not_to be_admin
    end

    it "correctly identifies admin role" do
      user.role = :admin
      user.roles = [ 'admin' ]
      expect(user).to be_admin
      expect(user).not_to be_student
      expect(user).not_to be_instructor
    end
  end

  describe "#can_manage_team?" do
    let(:team) { create(:team) }
    let(:user) { create(:user) }

    context "when user is admin" do
      before { user.update(role: :admin, roles: [ 'admin' ]) }

      it "returns true" do
        expect(user.can_manage_team?(team)).to be true
      end
    end

    context "when user is team owner" do
      before { team.update(owner: user) }

      it "returns true" do
        expect(user.can_manage_team?(team)).to be true
      end
    end

    context "when user is team manager" do
      before { create(:team_member, user: user, team: team, role: :manager) }

      it "returns true" do
        expect(user.can_manage_team?(team)).to be true
      end
    end

    context "when user is regular team member" do
      before { create(:team_member, user: user, team: team, role: :member) }

      it "returns false" do
        expect(user.can_manage_team?(team)).to be false
      end
    end
  end

  describe "callbacks" do
    describe "#downcase_email" do
      it "downcases email before validation" do
        user = create(:user, email: "USER@EXAMPLE.COM")
        expect(user.email).to eq("user@example.com")
      end
    end
  end

  describe "Devise methods" do
    let(:user) { create(:user) }

    describe "#jwt_payload" do
      it "returns the correct payload" do
        payload = user.jwt_payload
        expect(payload).to include(
          user_id: user.id,
          email: user.email,
          role: user.role,
          full_name: user.full_name
        )
      end
    end
  end

  describe ".from_omniauth" do
    let(:auth) do
      OpenStruct.new(
        provider: "google_oauth2",
        uid: "123456789",
        info: OpenStruct.new(
          email: "user@example.com",
          first_name: "John",
          last_name: "Doe",
          image: "https://example.com/image.jpg"
        )
      )
    end

    it "creates a new user from OAuth data" do
      user = described_class.from_omniauth(auth)
      expect(user).to be_persisted
      expect(user.email).to eq("user@example.com")
      expect(user.first_name).to eq("John")
      expect(user.last_name).to eq("Doe")
      expect(user.provider).to eq("google_oauth2")
      expect(user.uid).to eq("123456789")
    end

    it "finds existing user by provider and uid" do
      existing_user = create(:user, provider: "google_oauth2", uid: "123456789")
      user = described_class.from_omniauth(auth)
      expect(user).to eq(existing_user)
    end
  end
end
