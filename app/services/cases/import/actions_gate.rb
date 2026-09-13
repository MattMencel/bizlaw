# frozen_string_literal: true

module Cases
  class Import
    # The Action menu a Case offers. An Action kind is engine, so a Case may
    # price the kinds it offers and may not invent one. Everything else about an
    # Action — the cost, the lead time and the half it draws on — is the Case's.
    class ActionsGate < Gate
      REQUIRED_ACTION_KEYS = %w[cost lead_time_days half].freeze

      def check!
        raise InvalidCase, "#{path} authors no actions" unless actions.is_a?(Hash) && actions.any?

        actions.each do |kind, authored_action|
          unless CaseAction::KINDS.include?(kind)
            raise InvalidCase, "#{path} authors #{kind}, which is not an Action the engine knows"
          end

          validate_action!(kind, authored_action)
        end
      end

      private

      def validate_action!(kind, authored_action)
        # A lead time of zero is a legal Action, so an authored value is missing
        # only when it is nil, never when it is falsy.
        authored = authored_action.is_a?(Hash) ? authored_action : {}
        if REQUIRED_ACTION_KEYS.any? { |key| authored[key].nil? }
          raise InvalidCase, "#{path} authors #{kind} without #{REQUIRED_ACTION_KEYS.join(", ")}"
        end

        # Points and Days are whole. A fractional one would otherwise reach the
        # model and come back as a validation failure rather than as this
        # importer's own refusal.
        %w[cost lead_time_days].each do |key|
          next if authored[key].is_a?(Integer)

          raise InvalidCase,
            "#{path} authors #{kind} with a #{key.tr("_", " ")} of " \
            "#{authored[key].inspect}, which is not a whole number"
        end

        raise InvalidCase, "#{path} authors #{kind} costing nothing" unless authored["cost"] >= 1

        if authored["lead_time_days"].negative?
          raise InvalidCase, "#{path} authors #{kind} with a lead time reaching backwards"
        end

        return if DayBudget::HALVES.include?(authored["half"])

        raise InvalidCase,
          "#{path} authors #{kind} drawing on #{authored["half"]}, " \
          "which is not a half of the Action Budget"
      end
    end
  end
end
