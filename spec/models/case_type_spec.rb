# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseType, type: :model do
  # Test concerns
  it_behaves_like "has_timestamps"

  # Associations
  describe 'associations' do
    it { is_expected.to have_many(:documents).dependent(:destroy) }
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
  end
end
