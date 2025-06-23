require "rails_helper"

RSpec.describe "Course Invitation QR Codes", type: :request do
  let(:organization) { create(:organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:course_invitation) { create(:course_invitation, course: course) }
  let(:admin) { create(:user, :admin) }

  describe "GET /course_invitations/:token/qr_code" do
    context "when user is course instructor" do
      before { sign_in instructor }

      it "returns PNG QR code with default parameters" do
        get qr_code_course_invitation_path(course_invitation.token, format: "png")

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/png")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("course_invitation_#{course_invitation.token}.png")
        expect(response.body.length).to be > 0
      end

      it "returns SVG QR code when format is svg" do
        get qr_code_course_invitation_path(course_invitation.token, format: "svg")

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/svg+xml")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("course_invitation_#{course_invitation.token}.svg")
        expect(response.body).to include("<svg")
      end

      it "returns PNG QR code with custom size" do
        get qr_code_course_invitation_path(course_invitation.token, format: "png", size: 400)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/png")
        expect(response.body.length).to be > 0
      end

      it "redirects with error for invalid format" do
        get qr_code_course_invitation_path(course_invitation.token, format: "invalid")

        expect(response).to redirect_to(courses_path)
        expect(flash[:alert]).to eq("Invalid QR code format requested.")
      end
    end

    context "when user is admin" do
      before { sign_in admin }

      it "allows admin to download QR codes" do
        get qr_code_course_invitation_path(course_invitation.token, format: "png")

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/png")
      end
    end

    context "when user is not authorized" do
      let(:other_instructor) { create(:user, :instructor) }
      let(:student) { create(:user, :student) }

      it "denies access to other instructors" do
        sign_in other_instructor

        get qr_code_course_invitation_path(course_invitation.token, format: "png")

        expect(response).to redirect_to(courses_path)
        expect(flash[:alert]).to eq("You are not authorized to access this QR code.")
      end

      it "denies access to students" do
        sign_in student

        get qr_code_course_invitation_path(course_invitation.token, format: "png")

        expect(response).to redirect_to(courses_path)
        expect(flash[:alert]).to eq("You are not authorized to access this QR code.")
      end

      it "denies access to unauthenticated users" do
        get qr_code_course_invitation_path(course_invitation.token, format: "png")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid invitation token" do
      before { sign_in instructor }

      it "returns 404 for non-existent token" do
        get qr_code_course_invitation_path("INVALID", format: "png")

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
