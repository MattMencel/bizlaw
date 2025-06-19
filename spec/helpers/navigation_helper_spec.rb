# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization: organization) }
  let(:instructor) { create(:user, :instructor, organization: organization) }
  let(:admin) { create(:user, :admin, organization: organization) }
  let(:course) { create(:course, instructor: instructor, organization: organization) }
  let(:case_obj) { create(:case, course: course) }
  let(:team) { create(:team) }

  before do
    allow(helper).to receive(:user_signed_in?).and_return(true)
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:session).and_return({})
  end

  describe "#current_user_case" do
    context "when user has an active case in session" do
      before do
        # Create case team association
        create(:case_team, case: case_obj, team: team)
        user.teams << team
        allow(helper).to receive(:session).and_return({active_case_id: case_obj.id})
      end

      it "returns the case from session" do
        expect(helper.current_user_case).to eq(case_obj)
      end
    end

    context "when user has no active case in session" do
      before do
        # Create case team association
        create(:case_team, case: case_obj, team: team)
        user.teams << team
      end

      it "returns the first available case" do
        expect(helper.current_user_case).to eq(case_obj)
      end
    end

    context "when user is not signed in" do
      before do
        allow(helper).to receive(:user_signed_in?).and_return(false)
      end

      it "returns nil" do
        expect(helper.current_user_case).to be_nil
      end
    end
  end

  describe "#current_user_team" do
    before do
      create(:case_team, case: case_obj, team: team)
      user.teams << team
      allow(helper).to receive(:current_user_case).and_return(case_obj)
    end

    context "when user has an active team in session" do
      before do
        allow(helper).to receive(:session).and_return({active_team_id: team.id})
      end

      it "returns the team from session" do
        expect(helper.current_user_team).to eq(team)
      end
    end

    context "when user has no active team in session" do
      it "returns the first team in current case" do
        expect(helper.current_user_team).to eq(team)
      end
    end

    context "when there is no current case" do
      before do
        allow(helper).to receive(:current_user_case).and_return(nil)
      end

      it "returns nil" do
        expect(helper.current_user_team).to be_nil
      end
    end
  end

  describe "#can_access_section?" do
    context "for regular user" do
      it "allows access to basic sections" do
        expect(helper.can_access_section?("legal_workspace")).to be true
        expect(helper.can_access_section?("case_files")).to be true
        expect(helper.can_access_section?("negotiations")).to be true
        expect(helper.can_access_section?("personal")).to be true
      end

      it "denies access to administration section" do
        expect(helper.can_access_section?("administration")).to be false
      end
    end

    context "for instructor" do
      before do
        allow(helper).to receive(:current_user).and_return(instructor)
      end

      it "allows access to administration section" do
        expect(helper.can_access_section?("administration")).to be true
      end
    end

    context "for admin" do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
      end

      it "allows access to all sections" do
        expect(helper.can_access_section?("administration")).to be true
        expect(helper.can_access_section?("legal_workspace")).to be true
      end
    end

    context "when user is not signed in" do
      before do
        allow(helper).to receive(:user_signed_in?).and_return(false)
      end

      it "denies access to all sections" do
        expect(helper.can_access_section?("legal_workspace")).to be false
        expect(helper.can_access_section?("administration")).to be false
      end
    end
  end

  describe "#case_status_color" do
    it "returns correct colors for different statuses" do
      expect(helper.case_status_color("ready")).to eq("text-green-400")
      expect(helper.case_status_color("active")).to eq("text-green-400")
      expect(helper.case_status_color("pending")).to eq("text-yellow-400")
      expect(helper.case_status_color("waiting")).to eq("text-yellow-400")
      expect(helper.case_status_color("attention_needed")).to eq("text-red-400")
      expect(helper.case_status_color("overdue")).to eq("text-red-400")
      expect(helper.case_status_color("in_progress")).to eq("text-blue-400")
      expect(helper.case_status_color(nil)).to eq("text-gray-400")
      expect(helper.case_status_color("unknown")).to eq("text-gray-400")
    end
  end

  describe "#case_status_dot_color" do
    it "returns correct dot colors for different statuses" do
      expect(helper.case_status_dot_color("ready")).to eq("bg-green-400")
      expect(helper.case_status_dot_color("active")).to eq("bg-green-400")
      expect(helper.case_status_dot_color("pending")).to eq("bg-yellow-400")
      expect(helper.case_status_dot_color("waiting")).to eq("bg-yellow-400")
      expect(helper.case_status_dot_color("attention_needed")).to eq("bg-red-400")
      expect(helper.case_status_dot_color("overdue")).to eq("bg-red-400")
      expect(helper.case_status_dot_color("in_progress")).to eq("bg-blue-400")
      expect(helper.case_status_dot_color(nil)).to eq("bg-gray-400")
      expect(helper.case_status_dot_color("unknown")).to eq("bg-gray-400")
    end
  end

  describe "#nav_item_classes" do
    it "returns correct classes for different sizes and states" do
      # Test default size and inactive state
      classes = helper.nav_item_classes("/some/path", is_active: false)
      expect(classes).to include("flex items-center px-3 py-2 text-sm rounded-md")
      expect(classes).to include("text-gray-300 hover:bg-gray-700 hover:text-white")

      # Test active state
      classes = helper.nav_item_classes("/some/path", is_active: true)
      expect(classes).to include("bg-blue-600 text-white")

      # Test small size
      classes = helper.nav_item_classes("/some/path", size: "sm", is_active: false)
      expect(classes).to include("flex items-center px-2 py-1.5 text-xs rounded-sm")

      # Test large size
      classes = helper.nav_item_classes("/some/path", size: "lg", is_active: false)
      expect(classes).to include("flex items-center px-4 py-3 text-base rounded-md")
    end
  end

  describe "#nav_icon_size" do
    it "returns correct icon sizes" do
      expect(helper.nav_icon_size("sm")).to eq("h-4 w-4")
      expect(helper.nav_icon_size("md")).to eq("h-5 w-5")
      expect(helper.nav_icon_size("lg")).to eq("h-6 w-6")
      expect(helper.nav_icon_size(nil)).to eq("h-5 w-5") # default
    end
  end

  describe "#navigation_section_icon" do
    it "returns correct icons for sections" do
      expect(helper.navigation_section_icon("legal_workspace")).to eq("home")
      expect(helper.navigation_section_icon("case_files")).to eq("folder")
      expect(helper.navigation_section_icon("negotiations")).to eq("scale")
      expect(helper.navigation_section_icon("administration")).to eq("cog")
      expect(helper.navigation_section_icon("personal")).to eq("user")
      expect(helper.navigation_section_icon("unknown")).to eq("question-mark-circle")
    end
  end

  describe "#has_admin_privileges?" do
    context "for regular user" do
      it "returns false" do
        expect(helper.has_admin_privileges?).to be false
      end
    end

    context "for instructor" do
      before do
        allow(helper).to receive(:current_user).and_return(instructor)
      end

      it "returns true" do
        expect(helper.has_admin_privileges?).to be true
      end
    end

    context "for admin" do
      before do
        allow(helper).to receive(:current_user).and_return(admin)
      end

      it "returns true" do
        expect(helper.has_admin_privileges?).to be true
      end
    end

    context "when user is not signed in" do
      before do
        allow(helper).to receive(:user_signed_in?).and_return(false)
      end

      it "returns false" do
        expect(helper.has_admin_privileges?).to be false
      end
    end
  end

  describe "#nav_element_id" do
    it "generates unique IDs for navigation elements" do
      expect(helper.nav_element_id("section", "legal_workspace")).to eq("section-legal_workspace")
      expect(helper.nav_element_id("item", "case files")).to eq("item-case-files")
      expect(helper.nav_element_id("toggle", "Evidence Management")).to eq("toggle-evidence-management")
    end
  end

  describe "#context_switcher_data" do
    before do
      create(:case_team, case: case_obj, team: team)
      user.teams << team
      allow(helper).to receive(:current_user_case).and_return(case_obj)
      allow(helper).to receive(:current_user_team).and_return(team)
    end

    it "returns complete context data hash" do
      data = helper.context_switcher_data

      expect(data).to include(
        current_case: case_obj,
        current_team: team,
        user_role: user.primary_role
      )
    end
  end
end
