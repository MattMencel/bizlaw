# frozen_string_literal: true

module Cases
  class Import
    # The two Clients a Case authors — the bound each can be moved by, the face
    # they wear, and everything they say: the opening statement, the settlement
    # pair, the Reaction Bands and what they want out of the Terms.
    class ClientsGate < Gate
      # A band with one line repeats itself verbatim on a professor's second
      # Consult, which is the failure the several-variants rule exists to prevent.
      MINIMUM_VARIANTS = 2
      # Every fold has to land in a band, so the lowest one begins where the
      # Client does.
      THE_UNMOVED_CLIENT = 0

      # An Exhibit targets a Client, so a Case authors one for each Side.
      def check!
        raise InvalidCase, "#{path} authors no clients" unless clients.is_a?(Hash)

        unless clients.keys.sort == Side::ROLES.sort
          raise InvalidCase,
            "#{path} authors clients for #{clients.keys.sort.join(", ")} rather than " \
            "one for each of #{Side::ROLES.sort.join(", ")}"
        end

        clients.each do |role, authored_client|
          authored = authored_client.is_a?(Hash) ? authored_client : {}
          bound = authored["bound"]
          unless bound.is_a?(Integer) && bound.positive?
            raise InvalidCase,
              "#{path} authors the #{role} Client with a bound of #{bound.inspect}, " \
              "which is not a whole amount of money it can be moved by"
          end

          # What the Client says they want, on the Day the Team first sits down.
          # It is one of the Morning Briefing's what-you-start-with sections, so a
          # Case without it imports into a briefing with a hole in it.
          unless authored["opening_statement"].is_a?(String) && authored["opening_statement"].present?
            raise InvalidCase,
              "#{path} authors no opening statement for the #{role} Client, " \
              "which is what their Team reads on Day 1"
          end

          validate_portrait_seed!(role, authored["portrait_seed"])
          validate_settlement!(role, authored["settlement"])
          validate_bands!(role, authored["bands"])
          validate_aspirations!(role, authored["aspirations"])
        end

        validate_distinct_faces!
      end

      private

      # The whole of what a Case says about a Client's face. A Case that authors
      # none does not import, as loudly as one missing an opening statement: the
      # portrait is the Client's beat on both its occasions, and there is no
      # fallback face to draw under the words.
      def validate_portrait_seed!(role, seed)
        return if seed.is_a?(String) && seed.present?

        raise InvalidCase,
          "#{path} authors no portrait seed for the #{role} Client, " \
          "which is the whole of what a Case says about their face"
      end

      # The two Clients of one Case are the only pair anybody can ever see
      # together: Teams in different Simulations never meet, and a Team sees only
      # its own Client. So this is the one collision that matters, and it is
      # checked here rather than carried by the seed — two seeds collide when they
      # *compose* to the same person, which is a property of the part set and not
      # of the string.
      #
      # It follows that a Case can import today and stop importing after a reskin,
      # and that is correct: a set with a shallower hair group is a set in which
      # two faces the author had told apart are one face.
      def validate_distinct_faces!
        drawn = clients.transform_values { |authored| Portraits::Identity.for(authored["portrait_seed"]) }
        return if drawn.values.uniq.size == drawn.size

        raise InvalidCase,
          "#{path} seeds its #{drawn.keys.sort.join(" and ")} Clients to the same face " \
          "(#{drawn.values.first}); they are the one pair a Team ever sees together, " \
          "so reroll one of them"
      end

      # The settlement beat, keyed on which Side accepted. A Case that does not
      # supply both lines for both Clients does not import, as loudly as one
      # missing an opening statement: an executed instrument is the last thing a
      # Team reads and there is no fallback line to render under it.
      #
      # There are no variants. A settlement node is spoken exactly once, so a
      # speak-count never advances and a variant would always resolve to the
      # first — see ADR 0007.
      def validate_settlement!(role, authored_settlement)
        settlement = authored_settlement.is_a?(Hash) ? authored_settlement : {}
        missing = CaseClient::ACCEPTANCE_ROLES.reject do |acceptance_role|
          settlement[acceptance_role].is_a?(String) && settlement[acceptance_role].present?
        end
        return if missing.empty?

        raise InvalidCase,
          "#{path} authors no settlement line for the #{role} Client where they " \
          "#{missing.map { |acceptance_role| acceptance_role.tr("_", " ") }.join(" or ")}, " \
          "which is what they say over the executed instrument"
      end

      # The Reaction Band: what this Client says about where they stand, and the
      # only read a Team ever gets on how far their Client has moved. A Case that
      # authors none does not import, as loudly as one missing an opening
      # statement — a Consult would otherwise buy a Client with nothing to say.
      #
      # Two bands is engine and the edges are the Case's, so the keys are checked
      # against the engine's pair and the thresholds only for shape and order.
      def validate_bands!(role, authored_bands)
        bands = authored_bands.is_a?(Hash) ? authored_bands : {}
        if bands.empty?
          raise InvalidCase,
            "#{path} authors no bands for the #{role} Client, which is the whole of " \
            "what they can say when their Team consults them"
        end

        unless bands.keys.sort == CaseClientBand::BANDS.sort
          raise InvalidCase,
            "#{path} authors #{bands.keys.sort.join(", ")} for the #{role} Client rather than " \
            "one band for each of #{CaseClientBand::BANDS.join(", ")}"
        end

        CaseClientBand::BANDS.each { |key| validate_band!(role, key, bands.fetch(key)) }
        validate_band_edges!(role, bands)
      end

      def validate_band!(role, key, authored_band)
        band = authored_band.is_a?(Hash) ? authored_band : {}
        edge = band["at"]
        unless edge.is_a?(Numeric) && edge >= THE_UNMOVED_CLIENT && edge <= ClientShift::WHOLE_BOUND
          raise InvalidCase,
            "#{path} authors the #{role} Client's #{key} band at #{edge.inspect}, which is not " \
            "a fraction of the bound they cross into it at"
        end

        lines = band["lines"]
        unless lines.is_a?(Array) && lines.all? { |body| body.is_a?(String) && body.present? }
          raise InvalidCase,
            "#{path} authors the #{role} Client's #{key} band saying #{lines.inspect}, " \
            "which is not a set of lines they could say"
        end

        return if lines.size >= MINIMUM_VARIANTS

        # A node the engine can only ever speak one way. The Consult is priced to
        # be bought more than once, so the second one would come back word for
        # word — which is the tell the variants exist to prevent.
        raise InvalidCase,
          "#{path} gives the #{role} Client #{lines.size} line for their #{key} band; " \
          "a Consult can be bought twice, so a node carries at least #{MINIMUM_VARIANTS} variants"
      end

      # The bands are a partition of the bound, so the lowest begins where the
      # Client does and each one after it begins above the one before. A set that
      # starts above zero leaves an unmoved Client in no band at all, and the fold
      # would have nothing to answer with.
      #
      # Checked at the scale the column holds rather than as authored: two edges a
      # hair apart are one edge once stored, and the fold would then read a tie —
      # which is a partition with two answers for the same fraction of the bound,
      # and the wrong one for a Client who has not moved.
      def validate_band_edges!(role, bands)
        edges = CaseClientBand::BANDS.map do |key|
          bands.fetch(key)["at"].round(CaseClientBand.threshold_scale)
        end

        unless edges.first == THE_UNMOVED_CLIENT
          raise InvalidCase,
            "#{path} starts the #{role} Client's #{CaseClientBand::BANDS.first} band at " \
            "#{edges.first}, leaving a Client who has not moved yet in no band at all"
        end

        return if edges.each_cons(2).all? { |lower, higher| lower < higher }

        raise InvalidCase,
          "#{path} authors the #{role} Client's bands at #{edges.join(", ")}, which do not climb " \
          "through the bound in the order #{CaseClientBand::BANDS.join(", ")}"
      end

      # What a Client says out loud about the Terms. Sparse on purpose — a Term
      # absent here is one this Client is indifferent about — so an empty set is
      # authored rather than missing, and nothing checks for completeness.
      def validate_aspirations!(role, authored_aspirations)
        return if authored_aspirations.nil?

        unless authored_aspirations.is_a?(Hash)
          raise InvalidCase,
            "#{path} authors the #{role} Client's aspirations as " \
            "#{authored_aspirations.inspect}, which is not a set of Terms they want"
        end

        unknown = authored_aspirations.keys - terms
        if unknown.any?
          raise InvalidCase,
            "#{path} has the #{role} Client wanting #{unknown.join(", ")}, " \
            "which this Case authors no Term for"
        end

        authored_aspirations.each do |key, amount|
          # Absent on a Term that carries no figure, which is most of them. A
          # Client wanting an apology wants an apology.
          if amount && !(amount.is_a?(Integer) && amount.positive?)
            raise InvalidCase,
              "#{path} has the #{role} Client wanting #{amount.inspect} of #{key}, which is " \
              "neither a whole amount of money nor the Term wanted without a figure"
          end

          # Money is the one Term that carries a figure, which is the rule an
          # Offer's Terms are already held to. A Client aspiring to 5,000 of
          # apology would put a money figure on a Terms Board track whose other
          # two slots cannot hold one.
          next if (key == CaseTerm::MONEY) == !amount.nil?

          raise InvalidCase,
            "#{path} has the #{role} Client wanting #{key} " \
            "#{amount.nil? ? "without an amount" : "for #{amount}"}; " \
            "#{CaseTerm::MONEY} is the one Term an amount belongs to"
        end
      end
    end
  end
end
