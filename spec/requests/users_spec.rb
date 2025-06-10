# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:admin_user) { create(:user, role: :admin, organization: organization) }
  let(:instructor_user) { create(:user, role: :instructor, organization: organization) }
  let(:student_user) { create(:user, role: :student, organization: organization) }
  let(:other_student) { create(:user, role: :student, organization: organization) }
  let(:course) { create(:course, instructor: instructor_user, organization: organization) }

  before do
    # Directly create course enrollment to avoid timestamp validation issues
    CourseEnrollment.create!(
      user: student_user,
      course: course,
      enrolled_at: Time.current,
      status: 'active',
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  describe "POST /admin/impersonate/:id" do
    context "when user is an admin" do
      before { sign_in admin_user }

      it "allows impersonating another user in read-only mode" do
        post impersonate_user_path(student_user)

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq("You are now impersonating #{student_user.full_name} in read-only mode.")
        expect(session[:admin_user_id]).to eq(admin_user.id)
        expect(session[:impersonated_user_id]).to eq(student_user.id)
        expect(session[:impersonation_full_permissions]).to eq(false)
      end
    end

    context "when user is an instructor" do
      before { sign_in instructor_user }

      it "allows impersonating students in their courses" do
        post impersonate_user_path(student_user)

        expect(response).to redirect_to(dashboard_path)
        expect(flash[:notice]).to eq("You are now impersonating #{student_user.full_name} in read-only mode.")
        expect(session[:admin_user_id]).to eq(instructor_user.id)
        expect(session[:impersonated_user_id]).to eq(student_user.id)
        expect(session[:impersonation_full_permissions]).to eq(false)
      end

      it "denies impersonating students not in their courses" do
        post impersonate_user_path(other_student)

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when user is not signed in" do
      it "redirects to sign in" do
        post impersonate_user_path(student_user)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /admin/stop_impersonation" do
    context "when admin is impersonating" do
      before do
        sign_in admin_user
        post impersonate_user_path(student_user)
      end

      it "stops impersonation and clears all session data" do
        delete stop_impersonation_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq("Stopped impersonating. You are now #{admin_user.full_name}.")
        expect(session[:admin_user_id]).to be_nil
        expect(session[:impersonated_user_id]).to be_nil
        expect(session[:impersonation_full_permissions]).to be_nil
      end
    end

    context "when instructor is impersonating" do
      before do
        sign_in instructor_user
        post impersonate_user_path(student_user)
      end

      it "stops impersonation" do
        delete stop_impersonation_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq("Stopped impersonating. You are now #{instructor_user.full_name}.")
        expect(session[:admin_user_id]).to be_nil
        expect(session[:impersonated_user_id]).to be_nil
        expect(session[:impersonation_full_permissions]).to be_nil
      end
    end
  end

  describe "PATCH /admin/enable_full_permissions" do
    context "when admin is impersonating" do
      before do
        sign_in admin_user
        post impersonate_user_path(student_user)
      end

      it "enables full permissions for testing" do
        patch enable_full_permissions_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq("Full permissions enabled for testing purposes.")
        expect(session[:impersonation_full_permissions]).to eq(true)
      end
    end

    context "when instructor is impersonating" do
      before do
        sign_in instructor_user
        post impersonate_user_path(student_user)
      end

      it "denies access to enable full permissions" do
        patch enable_full_permissions_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end
  end

  describe "PATCH /admin/disable_full_permissions" do
    context "when admin is impersonating with full permissions" do
      before do
        sign_in admin_user
        post impersonate_user_path(student_user)
        patch enable_full_permissions_path
      end

      it "disables full permissions and returns to read-only mode" do
        patch disable_full_permissions_path

        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to eq("Returned to read-only mode.")
        expect(session[:impersonation_full_permissions]).to eq(false)
      end
    end
  end
end
