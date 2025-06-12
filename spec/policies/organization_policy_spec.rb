# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganizationPolicy, type: :policy do
  let(:admin_user) { create(:user, role: 'admin') }
  let(:instructor_user) { create(:user, role: 'instructor') }
  let(:student_user) { create(:user, role: 'student') }
  let(:organization) { create(:organization) }

  describe '.scope' do
    it 'returns all organizations for admin users' do
      org1 = create(:organization)
      org2 = create(:organization)

      scope = Pundit.policy_scope(admin_user, Organization)
      expect(scope).to include(org1, org2)
    end

    it 'returns empty scope for non-admin users' do
      org1 = create(:organization)
      org2 = create(:organization)

      instructor_scope = Pundit.policy_scope(instructor_user, Organization)
      student_scope = Pundit.policy_scope(student_user, Organization)

      expect(instructor_scope).to be_empty
      expect(student_scope).to be_empty
    end
  end

  describe 'admin permissions' do
    let(:policy) { described_class.new(admin_user, organization) }

    it 'allows all actions' do
      expect(policy.index?).to be true
      expect(policy.show?).to be true
      expect(policy.new?).to be true
      expect(policy.create?).to be true
      expect(policy.edit?).to be true
      expect(policy.update?).to be true
      expect(policy.destroy?).to be true
      expect(policy.activate?).to be true
      expect(policy.deactivate?).to be true
    end
  end

  describe 'instructor permissions' do
    let(:policy) { described_class.new(instructor_user, organization) }

    it 'denies all actions' do
      expect(policy.index?).to be false
      expect(policy.show?).to be false
      expect(policy.new?).to be false
      expect(policy.create?).to be false
      expect(policy.edit?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
      expect(policy.activate?).to be false
      expect(policy.deactivate?).to be false
    end
  end

  describe 'student permissions' do
    let(:policy) { described_class.new(student_user, organization) }

    it 'denies all actions' do
      expect(policy.index?).to be false
      expect(policy.show?).to be false
      expect(policy.new?).to be false
      expect(policy.create?).to be false
      expect(policy.edit?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
      expect(policy.activate?).to be false
      expect(policy.deactivate?).to be false
    end
  end

  describe 'unauthenticated user permissions' do
    let(:policy) { described_class.new(nil, organization) }

    it 'denies all actions' do
      expect(policy.index?).to be false
      expect(policy.show?).to be false
      expect(policy.new?).to be false
      expect(policy.create?).to be false
      expect(policy.edit?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
      expect(policy.activate?).to be false
      expect(policy.deactivate?).to be false
    end
  end
end
