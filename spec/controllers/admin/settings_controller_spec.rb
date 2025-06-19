# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SettingsController, type: :controller do
  let(:admin_user) { create(:user, role: "admin", roles: ["admin"]) }
  let(:regular_user) { create(:user, role: "student", roles: ["student"]) }

  describe "Admin access control" do
    context "when user is admin" do
      before { sign_in admin_user }

      describe "GET #index" do
        it "allows access to settings index" do
          get :index
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #show" do
        it "allows access to specific setting" do
          get :show, params: {id: "general"}
          expect(response).to have_http_status(:success)
        end
      end

      describe "PATCH #update" do
        it "allows updating settings" do
          patch :update, params: {
            id: "general",
            settings: {
              application_name: "Updated App Name",
              maintenance_mode: false
            }
          }
          expect(response).to redirect_to(admin_settings_path)
        end
      end
    end

    context "when user is not admin" do
      before { sign_in regular_user }

      describe "GET #index" do
        it "denies access" do
          get :index
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "GET #show" do
        it "denies access" do
          get :show, params: {id: "general"}
          expect(response).to have_http_status(:forbidden)
        end
      end

      describe "PATCH #update" do
        it "denies access" do
          patch :update, params: {
            id: "general",
            settings: {application_name: "Hacked"}
          }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when user is not signed in" do
      describe "GET #index" do
        it "redirects to sign in" do
          get :index
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe "Settings management" do
    before { sign_in admin_user }

    describe "GET #index" do
      it "displays available settings categories" do
        get :index
        expect(assigns(:settings_categories)).to include(
          "general", "security", "email", "features"
        )
      end
    end

    describe "GET #show" do
      it "loads specific settings category" do
        get :show, params: {id: "general"}
        expect(assigns(:category)).to eq("general")
        expect(assigns(:settings)).to be_present
      end

      it "handles invalid category gracefully" do
        get :show, params: {id: "invalid_category"}
        expect(response).to redirect_to(admin_settings_path)
        expect(flash[:alert]).to be_present
      end
    end

    describe "PATCH #update" do
      let(:valid_params) do
        {
          id: "general",
          settings: {
            application_name: "Business Law Platform",
            maintenance_mode: false,
            registration_enabled: true
          }
        }
      end

      it "updates settings successfully" do
        patch :update, params: valid_params
        expect(flash[:notice]).to eq("Settings updated successfully")
        expect(response).to redirect_to(admin_settings_path)
      end

      it "handles validation errors" do
        invalid_params = valid_params.deep_merge(
          settings: {application_name: ""}
        )

        patch :update, params: invalid_params
        expect(flash[:alert]).to be_present
        expect(response).to render_template(:show)
      end
    end
  end
end
