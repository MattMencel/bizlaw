# frozen_string_literal: true

module CaseHelper
  def case_status_classes(status)
    base_classes = "bg-opacity-10"
    case status.to_sym
    when :not_started
      "#{base_classes} bg-gray-500 text-gray-800"
    when :in_progress
      "#{base_classes} bg-blue-500 text-blue-800"
    when :submitted
      "#{base_classes} bg-yellow-500 text-yellow-800"
    when :reviewed
      "#{base_classes} bg-purple-500 text-purple-800"
    when :completed
      "#{base_classes} bg-green-500 text-green-800"
    else
      "#{base_classes} bg-gray-500 text-gray-800"
    end
  end

  def case_difficulty_classes(difficulty)
    base_classes = "bg-opacity-10"
    case difficulty.to_sym
    when :beginner
      "#{base_classes} bg-green-500 text-green-800"
    when :intermediate
      "#{base_classes} bg-yellow-500 text-yellow-800"
    when :advanced
      "#{base_classes} bg-red-500 text-red-800"
    else
      "#{base_classes} bg-gray-500 text-gray-800"
    end
  end

  def case_type_classes(case_type)
    base_classes = "bg-opacity-10"
    case case_type.to_s
    when "sexual_harassment"
      "#{base_classes} bg-red-500 text-red-800"
    when "discrimination"
      "#{base_classes} bg-orange-500 text-orange-800"
    when "wrongful_termination"
      "#{base_classes} bg-yellow-500 text-yellow-800"
    when "contract_dispute"
      "#{base_classes} bg-blue-500 text-blue-800"
    when "intellectual_property"
      "#{base_classes} bg-purple-500 text-purple-800"
    else
      "#{base_classes} bg-gray-500 text-gray-800"
    end
  end
end
