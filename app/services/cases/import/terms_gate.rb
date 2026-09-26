# frozen_string_literal: true

module Cases
  class Import
    # The vocabulary an Offer is built from and an Exhibit bears on.
    #
    # Each Term is a key and a label. The key is what the rest of the Case names
    # it by; the label is what a student reads, and the engine will not make one
    # up from the key.
    class TermsGate < Gate
      def check!
        unless terms.is_a?(Array) && terms.any? && terms.all? { |term| authored_key?(term) }
          raise InvalidCase, "#{path} authors no terms for an Offer to be built from"
        end

        unlabelled = terms.reject { |term| term["label"].is_a?(String) && term["label"].present? }
        if unlabelled.any?
          raise InvalidCase,
            "#{path} authors #{unlabelled.pluck("key").join(", ")} " \
            "with no label for a student to read"
        end

        duplicated = term_keys.tally.select { |_key, count| count > 1 }.keys
        return if duplicated.empty?

        raise InvalidCase, "#{path} authors #{duplicated.join(", ")} twice; Terms are atomic"
      end

      private

      def authored_key?(term) = term.is_a?(Hash) && term["key"].is_a?(String) && term["key"].present?
    end
  end
end
