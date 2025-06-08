# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseType, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:cases).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:difficulty_level) }
    it { is_expected.to validate_presence_of(:estimated_time) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:difficulty_level).with_values(beginner: 'beginner', intermediate: 'intermediate', advanced: 'advanced').with_prefix }
  end

  describe 'soft deletion' do
    let(:case_type) { create(:case_type) }

    it 'can be soft deleted' do
      expect { case_type.soft_delete }.to change { case_type.deleted_at }.from(nil)
    end

    it 'can be restored' do
      case_type.soft_delete
      expect { case_type.restore }.to change { case_type.deleted_at }.to(nil)
    end
  end
end
