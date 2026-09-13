# frozen_string_literal: true

module Cases
  class Import
    # The Budget a Case authors: the points a Day arrives with, the halves they
    # arrive in, and what an Exhibit costs out of the exchange one.
    class BudgetGate < Gate
      REQUIRED_BUDGET_KEYS =
        %w[per_day exchange_pool exhibit_price closing_knee closing_preparation
          closing_exchange].freeze
      # The Budget's whole numbers. `closing_knee` is the one fraction and is
      # checked on its own.
      BUDGET_COUNTS =
        %w[per_day exchange_pool exhibit_price closing_preparation closing_exchange].freeze

      # The floor belongs to the half itself, so it is the model's to state.
      PLAYABLE_EXCHANGE_HALF = DayBudget::PLAYABLE_EXCHANGE_HALF
      # What an Offer costs to commit. It is engine rather than authored, and the
      # Exhibit's price is checked against what is left of the pool over it.
      OFFER_COST = CommittedOffer::EXCHANGE_COST

      def check!
        raise InvalidCase, "#{path} authors no budget" unless budget.is_a?(Hash)

        missing = REQUIRED_BUDGET_KEYS.reject { |key| budget[key].present? }
        raise InvalidCase, "#{path} authors a budget missing #{missing.join(", ")}" if missing.any?

        validate_budget_shape!

        [["exchange_pool", "exchange half"], ["closing_exchange", "closing exchange half"]]
          .each do |key, name|
            next if budget[key] >= PLAYABLE_EXCHANGE_HALF

            raise InvalidCase,
              "#{path} authors a #{name} of #{budget[key]}, under the #{PLAYABLE_EXCHANGE_HALF} " \
              "points an Offer with one Exhibit behind it costs"
          end

        validate_exhibit_price!
      end

      private

      # The Exhibit's price and the exchange pool are one decision rather than
      # two. An Exhibit rides a committed Offer, so a price that puts the pair past
      # the pool prices out every Exhibit in the Case — at a pool of two an Exhibit
      # costing two means nothing can ever be played, and separation across the
      # joint grid falls from 84 to 10. The narrower of the two halves is the one
      # to check: the closing half only ever widens.
      def validate_exhibit_price!
        price = budget["exhibit_price"]
        unless price >= 1
          raise InvalidCase, "#{path} authors an Exhibit costing #{price}, which is not a spend"
        end

        return if OFFER_COST + price <= budget["exchange_pool"]

        raise InvalidCase,
          "#{path} prices an Exhibit at #{price} against an exchange half of " \
          "#{budget["exchange_pool"]}, which leaves no Offer for it to ride"
      end

      # Types and ranges before any comparison, because a value of the wrong shape
      # otherwise passes import and fails much later and much further away — a
      # string blows up the comparison below, and a negative allowance reaches the
      # Day it opens and trips a `day_budgets` CHECK mid-Simulation.
      def validate_budget_shape!
        BUDGET_COUNTS.each do |key|
          next if budget[key].is_a?(Integer)

          raise InvalidCase,
            "#{path} authors a budget #{key.tr("_", " ")} of #{budget[key].inspect}, " \
            "which is not a whole number of points"
        end

        knee = budget["closing_knee"]
        unless knee.is_a?(Numeric) && knee.positive? && knee <= 1
          raise InvalidCase,
            "#{path} authors a closing knee of #{knee.inspect}, which is not a " \
            "fraction of the Simulation"
        end

        if budget["closing_preparation"].negative?
          raise InvalidCase,
            "#{path} authors a closing preparation half of " \
            "#{budget["closing_preparation"]}, which is less than nothing"
        end

        # The taper takes a Section's Budget cut out of the preparation half and
        # never out of the brake, so a Budget authored under its own exchange pool
        # writes a negative preparation half on the first Day that opens.
        return if budget["per_day"] >= budget["exchange_pool"]

        raise InvalidCase,
          "#{path} authors #{budget["per_day"]} points a Day against an exchange " \
          "half of #{budget["exchange_pool"]}, leaving nothing to prepare with"
      end
    end
  end
end
