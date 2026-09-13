# frozen_string_literal: true

module Cases
  class Import
    # The vocabulary an Offer is built from and an Exhibit bears on.
    class TermsGate < Gate
      def check!
        unless terms.is_a?(Array) && terms.any? && terms.all?(String)
          raise InvalidCase, "#{path} authors no terms for an Offer to be built from"
        end

        duplicated = terms.tally.select { |_key, count| count > 1 }.keys
        return if duplicated.empty?

        raise InvalidCase, "#{path} authors #{duplicated.join(", ")} twice; Terms are atomic"
      end
    end
  end
end
