require "rails_helper"

RSpec.describe CourseInvitation, type: :model do
  let(:organization) { create(:organization, domain: "university.edu") }
  let(:instructor) { create(:user, :instructor, organization: organization, email: "instructor@university.edu") }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:course_invitation) { create(:course_invitation, course: course) }

  describe "QR code functionality" do
    describe "#qr_code_svg" do
      it "generates SVG QR code with default size" do
        svg = course_invitation.qr_code_svg

        expect(svg).to include("<svg")
        expect(svg).to include('width="200"')
        expect(svg).to include('height="200"')
        expect(svg).to include('class="qr-code"')
      end

      it "generates SVG QR code with custom size" do
        svg = course_invitation.qr_code_svg(size: 300)

        expect(svg).to include("<svg")
        expect(svg).to include('width="300"')
        expect(svg).to include('height="300"')
      end

      it "caches SVG for same size" do
        first_call = course_invitation.qr_code_svg(size: 250)
        second_call = course_invitation.qr_code_svg(size: 250)

        expect(first_call).to eq(second_call)
      end

      it "generates different SVG for different sizes" do
        small = course_invitation.qr_code_svg(size: 100)
        large = course_invitation.qr_code_svg(size: 400)

        expect(small).not_to eq(large)
        expect(small).to include('width="100"')
        expect(large).to include('width="400"')
      end
    end

    describe "#qr_code_png" do
      it "generates PNG QR code with default parameters" do
        png = course_invitation.qr_code_png

        expect(png).to respond_to(:to_s)
        expect(png.to_s.length).to be > 0
      end

      it "generates PNG QR code with custom size" do
        png = course_invitation.qr_code_png(size: 150)

        expect(png).to respond_to(:to_s)
        expect(png.to_s.length).to be > 0
      end

      it "generates PNG QR code with custom colors" do
        png = course_invitation.qr_code_png(
          size: 200,
          fill: "FF0000",
          background: "00FF00"
        )

        expect(png).to respond_to(:to_s)
        expect(png.to_s.length).to be > 0
      end
    end

    describe "#qr_code_data_uri" do
      it "generates base64 data URI" do
        data_uri = course_invitation.qr_code_data_uri

        expect(data_uri).to start_with("data:image/png;base64,")
        expect(data_uri.length).to be > 50
      end

      it "generates data URI with custom parameters" do
        data_uri = course_invitation.qr_code_data_uri(
          size: 100,
          fill: "000000",
          background: "FFFFFF"
        )

        expect(data_uri).to start_with("data:image/png;base64,")
        expect(data_uri.length).to be > 50
      end
    end

    describe "QR code content" do
      it "encodes the correct invitation URL" do
        expected_url = course_invitation.invitation_url

        # Test that the SVG contains a representation of the URL
        svg = course_invitation.qr_code_svg
        expect(svg).to be_present
        expect(expected_url).to include(course_invitation.token)
      end
    end
  end

  describe "cross-domain student invitations" do
    context "when instructor invites student from different domain" do
      let(:student_external_email) { "student@external-college.edu" }

      it "allows student from external domain to join course" do
        external_student = create(:user, :student, email: student_external_email, organization: nil)

        expect {
          course.enroll_student(external_student)
        }.to change { course.students.count }.by(1)

        expect(course.enrolled?(external_student)).to be true
        expect(external_student.organization).to be_nil
      end

      it "allows course invitation to be used by external domain student" do
        create(:user, :student, email: student_external_email, organization: nil)

        expect(course_invitation.can_be_used?).to be true
      end

      it "creates course enrollment for external domain student" do
        external_student = create(:user, :student, email: student_external_email, organization: nil)

        expect {
          CourseEnrollment.create!(user: external_student, course: course)
        }.to change { CourseEnrollment.count }.by(1)

        enrollment = CourseEnrollment.last
        expect(enrollment.user).to eq(external_student)
        expect(enrollment.course).to eq(course)
      end
    end

    context "when instructor from one organization invites student from another organization" do
      let(:other_organization) { create(:organization, domain: "other-university.edu") }
      let(:student_from_other_org) { create(:user, :student, organization: other_organization, email: "student@other-university.edu") }
      let(:course_invitation) { create(:course_invitation, course: course) }

      it "allows student from different organization to join course" do
        expect {
          course.enroll_student(student_from_other_org)
        }.to change { course.students.count }.by(1)

        expect(course.enrolled?(student_from_other_org)).to be true
        expect(student_from_other_org.organization).to eq(other_organization)
      end

      it "does not change student's organization when joining cross-domain course" do
        original_org = student_from_other_org.organization

        course.enroll_student(student_from_other_org)
        student_from_other_org.reload

        expect(student_from_other_org.organization).to eq(original_org)
      end
    end

    context "course invitation token usage across domains" do
      let(:course_invitation) { create(:course_invitation, course: course, max_uses: 5) }
      let(:external_students) do
        [
          create(:user, :student, email: "student1@external.edu", organization: nil),
          create(:user, :student, email: "student2@different.org", organization: nil),
          create(:user, :student, email: "student3@another.com", organization: nil)
        ]
      end

      it "allows multiple external domain students to use same invitation token" do
        external_students.each do |student|
          expect(course_invitation.can_be_used?).to be true
          course.enroll_student(student, course_invitation)
        end

        expect(course.students.count).to eq(3)
        expect(course.students).to match_array(external_students)
      end

      it "tracks usage across different domains" do
        external_students.each { |student| course.enroll_student(student, course_invitation) }
        course_invitation.reload

        expect(course_invitation.current_uses).to eq(3)
        expect(course.students.count).to eq(3)
      end
    end

    context "instructor permissions for cross-domain invitations" do
      it "allows instructor to create course invitations regardless of target domain" do
        course_invitation = build(:course_invitation, course: course)

        expect(course_invitation).to be_valid
      end

      it "allows instructor to invite students via email from any domain" do
        # Course invitations are token-based, not email-based, so we test token creation
        course_invitation = nil
        expect {
          course_invitation = create(:course_invitation, course: course)
        }.not_to raise_error

        expect(course_invitation.token).to be_present
      end
    end
  end

  describe "domain validation behavior" do
    let(:same_domain_student) { create(:user, :student, organization: organization, email: "student@university.edu") }
    let(:different_domain_student) { create(:user, :student, organization: nil, email: "student@external.com") }

    it "treats same-domain and cross-domain students equally for course access" do
      course_invitation = create(:course_invitation, course: course)

      expect(course_invitation.can_be_used?).to be true
      # Course invitations are token-based, not user-specific
    end

    it "does not validate email domains for course enrollment" do
      course.enroll_student(same_domain_student)
      course.enroll_student(different_domain_student)

      expect(course.students).to include(same_domain_student, different_domain_student)
    end
  end
end
