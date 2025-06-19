# frozen_string_literal: true

module ActivityHelper
  def activity_icon(action_type)
    return default_icon unless action_type
    case action_type.to_sym
    when :created
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z",
          clip_rule: "evenodd"
      end
    when :updated
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"
      end
    when :deleted
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z",
          clip_rule: "evenodd"
      end
    when :member_removed, :team_member_removed
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M11 6a3 3 0 11-6 0 3 3 0 016 0zM14 17a6 6 0 00-12 0h12zM13 8a1 1 0 100 2h4a1 1 0 100-2h-4z"
      end
    when :member_added, :team_member_added
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6zM16 7a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z"
      end
    when :status_changed
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z",
          clip_rule: "evenodd"
      end
    when :document_added
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M4 4a2 2 0 012-2h8a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 0v12h8V4H6z",
          clip_rule: "evenodd"
      end
    when :document_removed
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M4 4a2 2 0 012-2h8a2 2 0 012 2v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4zm2 0v12h8V4H6z",
          clip_rule: "evenodd"
      end
    when :comment_added
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M18 10c0 3.866-3.582 7-8 7a8.841 8.841 0 01-4.083-.98L2 17l1.338-3.123C2.493 12.767 2 11.434 2 10c0-3.866 3.582-7 8-7s8 3.134 8 7zM7 9H5v2h2V9zm8 0h-2v2h2V9zM9 9h2v2H9V9z",
          clip_rule: "evenodd"
      end
    else
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
          clip_rule: "evenodd"
      end
    end
  end

  def activity_description(activity)
    # Handle both generic activity objects and CaseEvent objects
    if activity.respond_to?(:user) && activity.respond_to?(:event_type)
      # CaseEvent object
      actor = activity.user&.full_name || "System"

      case activity.event_type.to_sym
      when :created
        "#{actor} created the case"
      when :updated
        "#{actor} updated case details"
      when :status_changed
        "#{actor} changed case status"
      when :document_added
        "#{actor} added a document"
      when :document_removed
        "#{actor} removed a document"
      when :team_member_added
        "#{actor} added a team member"
      when :team_member_removed
        "#{actor} removed a team member"
      when :comment_added
        "#{actor} added a comment"
      else
        "#{actor} performed an action"
      end
    else
      # Generic activity object (legacy)
      actor = activity.actor.is_a?(User) ? activity.actor.full_name : "System"
      target = activity.target_type.underscore.humanize.downcase

      case activity.action_type.to_sym
      when :created
        "#{actor} created this #{target}"
      when :updated
        "#{actor} updated #{target} details"
      when :deleted
        "#{actor} removed a #{target}"
      when :member_added
        "#{actor} added #{activity.target.user.full_name} to the team"
      when :member_removed
        "#{actor} removed #{activity.target.user.full_name} from the team"
      else
        "#{actor} performed an action on #{target}"
      end
    end
  end

  private

  def default_icon
    tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
      tag.path fill_rule: "evenodd",
        d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
        clip_rule: "evenodd"
    end
  end
end
