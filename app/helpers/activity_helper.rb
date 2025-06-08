# frozen_string_literal: true

module ActivityHelper
  def activity_icon(action_type)
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
    when :member_added
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6zM16 7a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z"
      end
    when :member_removed
      tag.svg class: "w-5 h-5 text-white", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M11 6a3 3 0 11-6 0 3 3 0 016 0zM14 17a6 6 0 00-12 0h12zM13 8a1 1 0 100 2h4a1 1 0 100-2h-4z"
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
    actor = activity.actor.is_a?(User) ? activity.actor.name : "System"
    target = activity.target_type.underscore.humanize.downcase

    case activity.action_type.to_sym
    when :created
      "#{actor} created this #{target}"
    when :updated
      "#{actor} updated #{target} details"
    when :deleted
      "#{actor} removed a #{target}"
    when :member_added
      "#{actor} added #{activity.target.user.name} to the team"
    when :member_removed
      "#{actor} removed #{activity.target.user.name} from the team"
    else
      "#{actor} performed an action on #{target}"
    end
  end
end
