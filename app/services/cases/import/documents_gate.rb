# frozen_string_literal: true

module Cases
  class Import
    # The documents a Case authors: the door each waits behind or the hand it
    # sits in at the open, and the Exhibit some of them carry.
    class DocumentsGate < Gate
      REQUIRED_DOCUMENT_KEYS = %w[title body].freeze
      # Provenance's authored three. A document names the Action it waits behind
      # or the hand it sits in at the open, and never both — that xor is what
      # makes *doors visible, contents hidden* checkable.
      HANDS = (CaseDocument::PROVENANCES - [CaseDocument::DISCOVERABLE]).freeze
      REQUIRED_EXHIBIT_KEYS = %w[target shift bears_on].freeze

      def check!
        raise InvalidCase, "#{path} authors no documents" unless documents.is_a?(Hash) && documents.any?

        documents.each { |identifier, authored| validate_document!(identifier, authored) }
      end

      private

      def validate_document!(identifier, authored_document)
        authored = authored_document.is_a?(Hash) ? authored_document : {}
        if REQUIRED_DOCUMENT_KEYS.any? { |key| authored[key].blank? }
          raise InvalidCase,
            "#{path} authors #{identifier} without #{REQUIRED_DOCUMENT_KEYS.join(", ")}"
        end

        validate_provenance!(identifier, authored)
        validate_exhibit!(identifier, authored["exhibit"])
        validate_open_hand_exhibit!(identifier, authored)
      end

      # The xor. Every discoverable document sits behind some Action, and nothing
      # a Team starts with can also be something it finds — which is the whole of
      # what makes *doors visible, contents hidden* a thing a spec can check.
      def validate_provenance!(identifier, authored)
        door = authored["action"]
        hand = authored["hand"]

        if door.present? == hand.present?
          raise InvalidCase,
            "#{path} authors #{identifier} with #{door.present? ? "both an action and a hand" :
              "neither an action nor a hand"}; a document waits behind one or sits in the other"
        end

        if hand.present? && !HANDS.include?(hand)
          raise InvalidCase,
            "#{path} puts #{identifier} in #{hand}, which is not a hand at the open"
        end

        return if hand.present?

        unless actions.key?(door)
          raise InvalidCase,
            "#{path} hides #{identifier} behind #{door}, which is not on this Case's Action menu"
        end

        return unless door == CaseAction::CONSULT_CLIENT

        # A Consult is answered by the Client rather than by paper, and until now
        # that was a comment on `CaseAction` rather than a rule — this importer
        # maps documents onto the menu by key and would have taken one.
        #
        # It is a rule because a historical read rests on it. `Days::Command`
        # writes the Docket row and lands a lead-zero spend's documents inside one
        # transaction, and a Consult is lead-zero: a shift landing there would
        # share the spend's timestamp, and the band folded as of that instant
        # would be order-ambiguous. Refusing the Case removes the tiebreak rather
        # than stating one — see ADR 0006.
        raise InvalidCase,
          "#{path} hides #{identifier} behind #{CaseAction::CONSULT_CLIENT}, which is answered " \
          "by the Client rather than by paper; a Consult yields no documents"
      end

      # Ammunition a Team walks in with is a position the Case authored and Par is
      # authored against it. An unfavorable Exhibit at the open is refused: its
      # shift would land before the first Day is played, spending the Client's
      # bound with no Docket line behind it and no beat to read it in.
      #
      # A document in both hands is in the hand of whichever Client it would
      # target, so it may carry no Exhibit at all.
      def validate_open_hand_exhibit!(identifier, authored)
        hand = authored["hand"]
        target = authored.dig("exhibit", "target")
        return if hand.blank? || target.nil?
        return if hand != CaseDocument::BOTH_SIDES && target != hand

        raise InvalidCase,
          "#{path} puts #{identifier} in #{hand}'s hand at the open carrying an Exhibit " \
          "against the #{target} Client, which would move them before the first Day is played"
      end

      # A document may carry an Exhibit and most do not. One that does carries a
      # target, a shift as a fraction of that target's bound, and the Terms it
      # bears on — all three or none of them.
      def validate_exhibit!(identifier, exhibit)
        return if exhibit.nil?

        unless exhibit.is_a?(Hash) && REQUIRED_EXHIBIT_KEYS.none? { |key| exhibit[key].blank? }
          raise InvalidCase,
            "#{path} gives #{identifier} an Exhibit without #{REQUIRED_EXHIBIT_KEYS.join(", ")}"
        end

        unless Side::ROLES.include?(exhibit["target"])
          raise InvalidCase,
            "#{path} points #{identifier}'s Exhibit at #{exhibit["target"]}, which is not a Client"
        end

        shift = exhibit["shift"]
        unless shift.is_a?(Numeric) && shift.positive? && shift <= 1
          raise InvalidCase,
            "#{path} gives #{identifier}'s Exhibit a shift of #{shift.inspect}, which is not a " \
            "fraction of the target Client's bound moving them toward settleability"
        end

        # Checked as authored rather than coerced: a lone Term written without a
        # list passes every check above, and would reach `import_documents` to be
        # iterated as a String rather than come back as this importer's refusal.
        bears_on = exhibit["bears_on"]
        unless bears_on.is_a?(Array) && bears_on.all? { |key| key.is_a?(String) && key.present? }
          raise InvalidCase,
            "#{path} has #{identifier}'s Exhibit bearing on #{bears_on.inspect}, " \
            "which is not a list of the Terms it bears on"
        end

        unknown = bears_on - terms
        return if unknown.empty?

        raise InvalidCase,
          "#{path} has #{identifier}'s Exhibit bearing on #{unknown.join(", ")}, " \
          "which this Case authors no Term for"
      end
    end
  end
end
