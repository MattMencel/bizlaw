# frozen_string_literal: true

module EventHelper
  def event_type_classes(event_type)
    base_classes = "bg-opacity-10"
    case event_type.to_sym
    when :created
      "#{base_classes} bg-green-500 text-green-800"
    when :updated
      "#{base_classes} bg-blue-500 text-blue-800"
    when :deleted
      "#{base_classes} bg-red-500 text-red-800"
    when :status_changed
      "#{base_classes} bg-purple-500 text-purple-800"
    when :document_added
      "#{base_classes} bg-yellow-500 text-yellow-800"
    when :document_removed
      "#{base_classes} bg-red-500 text-red-800"
    when :team_assigned
      "#{base_classes} bg-indigo-500 text-indigo-800"
    when :team_removed
      "#{base_classes} bg-red-500 text-red-800"
    when :comment_added
      "#{base_classes} bg-gray-500 text-gray-800"
    else
      "#{base_classes} bg-gray-500 text-gray-800"
    end
  end

  def event_type_icon(event_type)
    case event_type.to_sym
    when :created
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M10 5a1 1 0 011 1v3h3a1 1 0 110 2h-3v3a1 1 0 11-2 0v-3H6a1 1 0 110-2h3V6a1 1 0 011-1z",
          clip_rule: "evenodd"
      end
    when :updated
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"
      end
    when :deleted
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z",
          clip_rule: "evenodd"
      end
    when :status_changed
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z",
          clip_rule: "evenodd"
      end
    when :document_added
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M4 4a2 2 0 012-2h4.586A2 2 0 0112 2.586L15.414 6A2 2 0 0116 7.414V16a2 2 0 01-2 2H6a2 2 0 01-2-2V4z",
          clip_rule: "evenodd"
      end
    when :document_removed
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M6 2a2 2 0 00-2 2v12a2 2 0 002 2h8a2 2 0 002-2V7.414A2 2 0 0015.414 6L12 2.586A2 2 0 0010.586 2H6zm1 8a1 1 0 100 2h6a1 1 0 100-2H7z",
          clip_rule: "evenodd"
      end
    when :team_assigned
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z"
      end
    when :team_removed
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path d: "M11 6a3 3 0 11-6 0 3 3 0 016 0zM14 17a6 6 0 00-12 0h12zM13 8a1 1 0 100 2h4a1 1 0 100-2h-4z"
      end
    when :comment_added
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M18 5v8a2 2 0 01-2 2h-5l-5 4v-4H4a2 2 0 01-2-2V5a2 2 0 012-2h12a2 2 0 012 2zM7 8H5v2h2V8zm2 0h2v2H9V8zm6 0h-2v2h2V8z",
          clip_rule: "evenodd"
      end
    else
      tag.svg class: "w-5 h-5", fill: "currentColor", viewBox: "0 0 20 20" do
        tag.path fill_rule: "evenodd",
          d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
          clip_rule: "evenodd"
      end
    end
  end

  def event_description(event)
    actor = event.user.name
    case event.event_type.to_sym
    when :created
      "#{actor} created this case"
    when :updated
      "#{actor} updated case details"
    when :deleted
      "#{actor} deleted this case"
    when :status_changed
      "#{actor} changed status to #{event.details["new_status"].titleize}"
    when :document_added
      "#{actor} added document '#{event.details["document_title"]}'"
    when :document_removed
      "#{actor} removed document '#{event.details["document_title"]}'"
    when :team_assigned
      "#{actor} assigned team '#{event.details["team_name"]}' as #{event.details["role"]}"
    when :team_removed
      "#{actor} removed team '#{event.details["team_name"]}'"
    when :comment_added
      "#{actor} added a comment"
    else
      "#{actor} performed an action"
    end
  end
end
