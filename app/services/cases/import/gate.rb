# frozen_string_literal: true

module Cases
  class Import
    # What one authored object of a Case refuses on. A gate reads the parsed
    # Hash and touches no table, so it can say everything it has to say before
    # the import's transaction opens.
    #
    # It is not a second seam. `Cases::Import` stays the one path authored Case
    # data enters the engine through, and a gate is reached only from its
    # `validate!` — which is why the verb is `check!` rather than `call` and why
    # these live under `Import` rather than beside it.
    class Gate
      def self.check!(path, data) = new(path, data).check!

      def initialize(path, data)
        @path = path
        @data = data
      end

      private

      attr_reader :path, :data

      def actions = data["actions"]

      def budget = data["budget"]

      def clients = data["clients"]

      def terms = data["terms"]

      # The keys the rest of a Case names its Terms by. Read leniently, because
      # the gates that name Terms run before `TermsGate` has said whether the
      # list is well formed, and a malformed one is that gate's refusal.
      def term_keys = Array(terms).filter_map { |term| term["key"] if term.is_a?(Hash) }

      def documents = data["documents"]
    end
  end
end
