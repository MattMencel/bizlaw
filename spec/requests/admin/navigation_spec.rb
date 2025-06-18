# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Navigation', type: :request do
  let(:admin_user) { create(:user, role: 'admin', roles: ['admin']) }
  let(:org_admin_user) { create(:user, role: 'org_admin', roles: ['org_admin']) }
  let(:regular_user) { create(:user, role: 'student', roles: ['student']) }

  describe 'Admin route accessibility' do
    context 'when signed in as admin' do
      before { sign_in admin_user }

      it 'allows access to admin organizations path' do
        get admin_organizations_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin settings path' do
        get admin_settings_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin dashboard path' do
        get admin_dashboard_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin licenses path' do
        get admin_licenses_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin users path' do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when signed in as org_admin' do
      before { sign_in org_admin_user }

      it 'allows access to admin organizations path' do
        get admin_organizations_path
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin users path' do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it 'denies access to admin settings path' do
        get admin_settings_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to admin licenses path' do
        get admin_licenses_path
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when signed in as regular user' do
      before { sign_in regular_user }

      it 'denies access to admin organizations path' do
        get admin_organizations_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to admin settings path' do
        get admin_settings_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to admin dashboard path' do
        get admin_dashboard_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to admin licenses path' do
        get admin_licenses_path
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies access to admin users path' do
        get admin_users_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'Navigation helper methods' do
    before { sign_in admin_user }

    it 'provides correct admin dashboard path' do
      expect(admin_dashboard_path).to eq('/admin/dashboard')
    end

    it 'provides correct admin settings path' do
      expect(admin_settings_path).to eq('/admin/settings')
    end

    it 'provides correct admin organizations path (plural)' do
      expect(admin_organizations_path).to eq('/admin/organizations')
    end

    it 'provides correct admin licenses path' do
      expect(admin_licenses_path).to eq('/admin/licenses')
    end
  end

  describe 'Route existence validation' do
    it 'has admin dashboard route defined' do
      expect { get admin_dashboard_path }.not_to raise_error
    end

    it 'has admin settings route defined' do
      expect { get admin_settings_path }.not_to raise_error
    end

    it 'has admin organizations route defined (plural)' do
      expect { get admin_organizations_path }.not_to raise_error
    end

    it 'has admin licenses route defined' do
      expect { get admin_licenses_path }.not_to raise_error
    end

    it 'does not have admin organization route (singular)' do
      expect { admin_organization_path }.to raise_error(NoMethodError)
    end
  end
end