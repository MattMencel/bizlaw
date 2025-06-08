# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:user) { build_stubbed(:user) }
  let(:record) { double('Record') }
  let(:policy) { described_class.new(user, record) }

  describe 'default permissions' do
    it 'denies index access by default' do
      expect(policy.index?).to be false
    end

    it 'denies show access by default' do
      expect(policy.show?).to be false
    end

    it 'denies create access by default' do
      expect(policy.create?).to be false
    end

    it 'denies new access by default' do
      expect(policy.new?).to be false
    end

    it 'denies update access by default' do
      expect(policy.update?).to be false
    end

    it 'denies edit access by default' do
      expect(policy.edit?).to be false
    end

    it 'denies destroy access by default' do
      expect(policy.destroy?).to be false
    end
  end

  describe 'convenience methods' do
    it 'delegates new? to create?' do
      expect(policy.new?).to eq(policy.create?)
    end

    it 'delegates edit? to update?' do
      expect(policy.edit?).to eq(policy.update?)
    end
  end

  describe ApplicationPolicy::Scope do
    let(:scope) { double('Scope') }
    let(:policy_scope) { described_class::Scope.new(user, scope) }

    describe '#resolve' do
      it 'raises NotImplementedError' do
        expect { policy_scope.resolve }.to raise_error(NotImplementedError, /You must define #resolve/)
      end
    end
  end
end
