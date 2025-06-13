# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject(:organization) { create(:organization) }

  # Test concerns
  it_behaves_like "has_uuid"
  it_behaves_like "has_timestamps"
  it_behaves_like "soft_deletable"

  # Associations
  describe 'associations' do
    it { is_expected.to belong_to(:license).optional }
    it { is_expected.to have_many(:users).dependent(:nullify) }
    it { is_expected.to have_many(:terms).dependent(:destroy) }
    it { is_expected.to have_many(:courses).dependent(:destroy) }
    it { is_expected.to have_many(:instructors) }
    it { is_expected.to have_many(:students) }
    it { is_expected.to have_many(:admins) }
    it { is_expected.to have_many(:org_admins) }
  end

  # Validations
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_length_of(:domain).is_at_most(100) }
    it { is_expected.to validate_uniqueness_of(:domain).case_insensitive }
    it { is_expected.to validate_length_of(:slug).is_at_most(50) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }

    describe 'domain format' do
      it 'accepts valid domain formats' do
        valid_domains = ['university.edu', 'college.org', 'school.ac.uk']
        valid_domains.each do |domain|
          organization.domain = domain
          expect(organization).to be_valid
        end
      end

      it 'rejects invalid domain formats' do
        invalid_domains = ['invalid', 'no-dot', 'invalid.', 'domain.c']
        invalid_domains.each do |domain|
          organization.domain = domain
          expect(organization).not_to be_valid
        end
      end
    end

    describe 'slug format' do
      it 'accepts valid slug formats' do
        valid_slugs = ['test-university', 'school123', 'college-name']
        valid_slugs.each do |slug|
          organization.slug = slug
          expect(organization).to be_valid
        end
      end

      it 'rejects invalid slug formats when bypassing normalization' do
        # Test the format validation directly by setting slug after name
        org = build(:organization, name: 'Test University')
        org.slug = 'invalid_slug!'
        expect(org).not_to be_valid
        expect(org.errors[:slug]).to include('must contain only lowercase letters, numbers, and hyphens')
      end
    end
  end

  # Scopes
  describe 'scopes' do
    let!(:active_org) { create(:organization, active: true) }
    let!(:inactive_org) { create(:organization, active: false) }

    describe '.active' do
      it 'returns only active organizations' do
        expect(described_class.active).to include(active_org)
        expect(described_class.active).not_to include(inactive_org)
      end
    end

    describe '.by_domain' do
      it 'finds organization by domain' do
        expect(described_class.by_domain(active_org.domain)).to include(active_org)
      end

      it 'is case insensitive' do
        expect(described_class.by_domain(active_org.domain.upcase)).to include(active_org)
      end
    end

    describe '.search_by_name' do
      let!(:university) { create(:organization, name: 'Test University') }

      it 'finds organizations by partial name match' do
        expect(described_class.search_by_name('test')).to include(university)
        expect(described_class.search_by_name('university')).to include(university)
      end

      it 'is case insensitive' do
        expect(described_class.search_by_name('TEST')).to include(university)
      end
    end
  end

  # Instance methods
  describe '#display_name' do
    it 'returns the organization name' do
      organization.name = 'Test University'
      expect(organization.display_name).to eq('Test University')
    end
  end

  describe '#branded_url' do
    it 'returns branded URL without path' do
      organization.slug = 'test-university'
      expect(organization.branded_url).to eq('test-university.bizlaw.edu')
    end

    it 'returns branded URL with path' do
      organization.slug = 'test-university'
      expect(organization.branded_url('/courses')).to eq('test-university.bizlaw.edu/courses')
    end
  end

  describe '#full_domain_name' do
    it 'returns full branded domain' do
      organization.slug = 'test-university'
      expect(organization.full_domain_name).to eq('test-university.bizlaw.edu')
    end
  end

  describe '#user_belongs_to_organization?' do
    let(:user) { create(:user, email: 'user@test.edu') }

    it 'returns true for matching domain' do
      organization.domain = 'test.edu'
      expect(organization.user_belongs_to_organization?(user)).to be true
    end

    it 'returns false for non-matching domain' do
      organization.domain = 'other.edu'
      expect(organization.user_belongs_to_organization?(user)).to be false
    end

    it 'returns false for nil user' do
      expect(organization.user_belongs_to_organization?(nil)).to be false
    end
  end

  describe 'callbacks' do
    describe 'slug normalization' do
      it 'generates slug from name if blank' do
        org = build(:organization, name: 'Test University', slug: nil)
        org.valid?
        expect(org.slug).to eq('test-university')
      end

      it 'normalizes existing slug' do
        org = build(:organization, slug: 'Test-University')
        org.valid?
        expect(org.slug).to eq('test-university')
      end
    end

    describe 'domain normalization' do
      it 'downcases domain' do
        org = build(:organization, domain: 'Test.EDU')
        org.valid?
        expect(org.domain).to eq('test.edu')
      end
    end
  end
end
