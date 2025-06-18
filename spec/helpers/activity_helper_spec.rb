# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityHelper, type: :helper do
  describe "#activity_icon" do
    context "with standard activity types" do
      it "returns plus icon for created action" do
        icon = helper.activity_icon(:created)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("currentColor")
        expect(icon).to include("viewBox=\"0 0 20 20\"")
        expect(icon).to include("fill_rule=\"evenodd\"")
      end
      
      it "returns edit icon for updated action" do
        icon = helper.activity_icon(:updated)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("currentColor")
        expect(icon).to include("path")
      end
      
      it "returns trash icon for deleted action" do
        icon = helper.activity_icon(:deleted)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
        expect(icon).to include("clip_rule=\"evenodd\"")
      end
      
      it "returns arrow icon for status_changed action" do
        icon = helper.activity_icon(:status_changed)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
      end
    end
    
    context "with team member activity types" do
      it "returns user minus icon for member_removed action" do
        icon = helper.activity_icon(:member_removed)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("path")
      end
      
      it "returns user plus icon for member_added action" do
        icon = helper.activity_icon(:member_added)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("path")
      end
      
      it "returns user minus icon for team_member_removed action" do
        icon = helper.activity_icon(:team_member_removed)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
      end
      
      it "returns user plus icon for team_member_added action" do
        icon = helper.activity_icon(:team_member_added)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
      end
    end
    
    context "with document activity types" do
      it "returns document icon for document_added action" do
        icon = helper.activity_icon(:document_added)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
        expect(icon).to include("clip_rule=\"evenodd\"")
      end
      
      it "returns document icon for document_removed action" do
        icon = helper.activity_icon(:document_removed)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
      end
    end
    
    context "with comment activity types" do
      it "returns chat icon for comment_added action" do
        icon = helper.activity_icon(:comment_added)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
        expect(icon).to include("clip_rule=\"evenodd\"")
      end
    end
    
    context "with unknown action types" do
      it "returns default info icon for unknown action" do
        icon = helper.activity_icon(:unknown_action)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
        expect(icon).to include("clip_rule=\"evenodd\"")
      end
      
      it "returns default info icon for nil action" do
        icon = helper.activity_icon(nil)
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
      end
      
      it "returns default info icon for empty string" do
        icon = helper.activity_icon("")
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
      end
    end
    
    context "with string action types" do
      it "handles string action types correctly" do
        icon = helper.activity_icon("created")
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
        expect(icon).to include("fill_rule=\"evenodd\"")
      end
      
      it "handles string action types for team members" do
        icon = helper.activity_icon("team_member_added")
        
        expect(icon).to include("svg")
        expect(icon).to include("w-5 h-5 text-white")
      end
    end
  end

  describe "#activity_description" do
    let(:user) { create(:user, first_name: "John", last_name: "Doe") }
    
    context "with CaseEvent objects" do
      let(:case_event) do
        instance_double("CaseEvent",
          user: user,
          event_type: "created",
          respond_to?: true
        )
      end
      
      before do
        allow(case_event).to receive(:respond_to?).with(:user).and_return(true)
        allow(case_event).to receive(:respond_to?).with(:event_type).and_return(true)
      end
      
      it "handles created event" do
        allow(case_event).to receive(:event_type).and_return("created")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe created the case")
      end
      
      it "handles updated event" do
        allow(case_event).to receive(:event_type).and_return("updated")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe updated case details")
      end
      
      it "handles status_changed event" do
        allow(case_event).to receive(:event_type).and_return("status_changed")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe changed case status")
      end
      
      it "handles document_added event" do
        allow(case_event).to receive(:event_type).and_return("document_added")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe added a document")
      end
      
      it "handles document_removed event" do
        allow(case_event).to receive(:event_type).and_return("document_removed")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe removed a document")
      end
      
      it "handles team_member_added event" do
        allow(case_event).to receive(:event_type).and_return("team_member_added")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe added a team member")
      end
      
      it "handles team_member_removed event" do
        allow(case_event).to receive(:event_type).and_return("team_member_removed")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe removed a team member")
      end
      
      it "handles comment_added event" do
        allow(case_event).to receive(:event_type).and_return("comment_added")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe added a comment")
      end
      
      it "handles unknown event types" do
        allow(case_event).to receive(:event_type).and_return("unknown_event")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe performed an action")
      end
      
      it "handles nil user with System fallback" do
        allow(case_event).to receive(:user).and_return(nil)
        allow(case_event).to receive(:event_type).and_return("created")
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("System created the case")
      end
      
      it "handles symbol event types" do
        allow(case_event).to receive(:event_type).and_return(:created)
        
        description = helper.activity_description(case_event)
        
        expect(description).to eq("John Doe created the case")
      end
    end
    
    context "with legacy activity objects" do
      let(:target_user) { create(:user, first_name: "Jane", last_name: "Smith") }
      let(:activity) do
        instance_double("Activity",
          actor: user,
          action_type: "created",
          target_type: "Team",
          target: instance_double("Target", user: target_user),
          respond_to?: false
        )
      end
      
      before do
        allow(activity).to receive(:respond_to?).with(:user).and_return(false)
        allow(activity).to receive(:respond_to?).with(:event_type).and_return(false)
        # User model uses full_name method
        allow(user).to receive(:is_a?).with(User).and_return(true)
        allow(user).to receive(:full_name).and_return("John Doe")
      end
      
      it "handles created action" do
        allow(activity).to receive(:action_type).and_return("created")
        allow(activity).to receive(:target_type).and_return("Team")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe created this team")
      end
      
      it "handles updated action" do
        allow(activity).to receive(:action_type).and_return("updated")
        allow(activity).to receive(:target_type).and_return("Case")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe updated case details")
      end
      
      it "handles deleted action" do
        allow(activity).to receive(:action_type).and_return("deleted")
        allow(activity).to receive(:target_type).and_return("Document")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe removed a document")
      end
      
      it "handles member_added action" do
        allow(activity).to receive(:action_type).and_return("member_added")
        allow(activity).to receive(:target_type).and_return("TeamMember")
        allow(target_user).to receive(:full_name).and_return("Jane Smith")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe added Jane Smith to the team")
      end
      
      it "handles member_removed action" do
        allow(activity).to receive(:action_type).and_return("member_removed")
        allow(activity).to receive(:target_type).and_return("TeamMember")
        allow(target_user).to receive(:full_name).and_return("Jane Smith")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe removed Jane Smith from the team")
      end
      
      it "handles unknown action types" do
        allow(activity).to receive(:action_type).and_return("unknown_action")
        allow(activity).to receive(:target_type).and_return("Resource")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe performed an action on resource")
      end
      
      it "handles symbol action types" do
        allow(activity).to receive(:action_type).and_return(:created)
        allow(activity).to receive(:target_type).and_return("Team")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe created this team")
      end
      
      it "handles system actor" do
        allow(activity).to receive(:actor).and_return("System")
        allow(activity).to receive(:action_type).and_return("created")
        allow(activity).to receive(:target_type).and_return("Team")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("System created this team")
      end
      
      it "handles underscore conversion in target type" do
        allow(activity).to receive(:action_type).and_return("created")
        allow(activity).to receive(:target_type).and_return("CaseEvent")
        
        description = helper.activity_description(activity)
        
        expect(description).to eq("John Doe created this case event")
      end
    end
    
    context "with edge cases" do
      it "handles activity object without proper methods" do
        broken_activity = OpenStruct.new
        
        expect { helper.activity_description(broken_activity) }.to raise_error(NoMethodError)
      end
      
      it "handles nil activity gracefully by raising error" do
        expect { helper.activity_description(nil) }.to raise_error(NoMethodError)
      end
    end
  end
  
  describe "icon styling consistency" do
    let(:all_action_types) do
      [:created, :updated, :deleted, :member_removed, :team_member_removed,
       :member_added, :team_member_added, :status_changed, :document_added,
       :document_removed, :comment_added, :unknown_action]
    end
    
    it "ensures all icons have consistent CSS classes" do
      all_action_types.each do |action_type|
        icon = helper.activity_icon(action_type)
        
        expect(icon).to include("w-5 h-5 text-white"), "Icon for #{action_type} should have consistent size and color classes"
        expect(icon).to include("currentColor"), "Icon for #{action_type} should use currentColor for fill"
        expect(icon).to include("viewBox=\"0 0 20 20\""), "Icon for #{action_type} should have standard viewBox"
      end
    end
    
    it "ensures all icons are valid SVG elements" do
      all_action_types.each do |action_type|
        icon = helper.activity_icon(action_type)
        
        expect(icon).to include("<svg"), "Icon for #{action_type} should be an SVG element"
        expect(icon).to include("</svg>"), "Icon for #{action_type} should have closing SVG tag"
        expect(icon).to include("path"), "Icon for #{action_type} should contain path elements"
      end
    end
  end
end