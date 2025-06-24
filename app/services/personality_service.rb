# frozen_string_literal: true

class PersonalityService
  PERSONALITY_DEFINITIONS = [
    {
      "type" => "aggressive",
      "name" => "Aggressive Negotiator",
      "traits" => [
        "Direct and confrontational communication",
        "High expectations and demands",
        "Quick to express dissatisfaction",
        "Focuses on maximum compensation",
        "Uses strong language and ultimatums"
      ],
      "communication_style" => {
        "tone" => "assertive, demanding",
        "language_patterns" => ["demand", "insist", "require", "unacceptable", "insufficient", "must"],
        "negotiation_approach" => "confrontational, high-pressure"
      },
      "satisfaction_modifiers" => {
        "base_threshold" => 75, # Harder to please
        "positive_multiplier" => 1.2,
        "negative_multiplier" => 0.7
      }
    },
    {
      "type" => "cautious",
      "name" => "Cautious Evaluator",
      "traits" => [
        "Careful consideration of all options",
        "Risk-averse decision making",
        "Seeks detailed explanations",
        "Values stability and predictability",
        "Methodical evaluation process"
      ],
      "communication_style" => {
        "tone" => "measured, careful",
        "language_patterns" => ["consider", "evaluate", "review", "careful", "thoughtful", "analyze"],
        "negotiation_approach" => "methodical, thorough analysis"
      },
      "satisfaction_modifiers" => {
        "base_threshold" => 60,
        "positive_multiplier" => 1.0,
        "negative_multiplier" => 1.0
      }
    },
    {
      "type" => "emotional",
      "name" => "Emotional Responder",
      "traits" => [
        "Strong emotional reactions to offers",
        "Personal investment in outcomes",
        "Expresses feelings openly",
        "Values validation and understanding",
        "Mood significantly affects decisions"
      ],
      "communication_style" => {
        "tone" => "expressive, feeling-based",
        "language_patterns" => ["feel", "emotional", "upset", "frustrated", "concerned", "worried"],
        "negotiation_approach" => "emotion-driven, relationship-focused"
      },
      "satisfaction_modifiers" => {
        "base_threshold" => 50,
        "positive_multiplier" => 1.3, # More extreme reactions
        "negative_multiplier" => 0.6
      }
    },
    {
      "type" => "pragmatic",
      "name" => "Pragmatic Realist",
      "traits" => [
        "Focuses on practical outcomes",
        "Business-minded approach",
        "Accepts reasonable compromises",
        "Values efficiency and results",
        "Balances costs and benefits"
      ],
      "communication_style" => {
        "tone" => "practical, business-like",
        "language_patterns" => ["practical", "realistic", "business", "sensible", "reasonable", "efficient"],
        "negotiation_approach" => "results-oriented, compromise-willing"
      },
      "satisfaction_modifiers" => {
        "base_threshold" => 55,
        "positive_multiplier" => 1.1,
        "negative_multiplier" => 0.9
      }
    },
    {
      "type" => "perfectionist",
      "name" => "Perfectionist Standards",
      "traits" => [
        "Extremely high standards",
        "Detail-oriented analysis",
        "Difficulty accepting compromises",
        "Seeks optimal outcomes",
        "Critical of subpar offers"
      ],
      "communication_style" => {
        "tone" => "exacting, critical",
        "language_patterns" => ["perfect", "optimal", "precise", "inadequate", "substandard", "excellence"],
        "negotiation_approach" => "meticulous, high-standard"
      },
      "satisfaction_modifiers" => {
        "base_threshold" => 80, # Very hard to please
        "positive_multiplier" => 1.1,
        "negative_multiplier" => 0.5
      }
    }
  ].freeze

  class << self
    def available_personalities
      PERSONALITY_DEFINITIONS
    end

    def assign_personalities(case_instance)
      # Use case ID as seed for deterministic assignment
      random = Random.new(case_instance.id.hash)

      available_types = PERSONALITY_DEFINITIONS.pluck("type")

      # Ensure different personalities for plaintiff and defendant
      plaintiff_personality = available_types.sample(random: random)
      remaining_types = available_types - [plaintiff_personality]
      defendant_personality = remaining_types.sample(random: random)

      {
        plaintiff_personality: plaintiff_personality,
        defendant_personality: defendant_personality
      }
    end

    def get_personality_traits(personality_type)
      personality = PERSONALITY_DEFINITIONS.find { |p| p["type"] == personality_type }
      raise ArgumentError, "Unknown personality type: #{personality_type}" unless personality

      personality
    end

    def personality_influences_satisfaction(personality_type, base_satisfaction, amount:, role:)
      traits = get_personality_traits(personality_type)
      modifiers = traits["satisfaction_modifiers"]

      # Adjust based on personality threshold
      adjusted = if base_satisfaction >= modifiers["base_threshold"]
        (base_satisfaction * modifiers["positive_multiplier"]).round
      else
        (base_satisfaction * modifiers["negative_multiplier"]).round
      end

      # Role-specific adjustments
      if role == "plaintiff"
        # Plaintiff generally wants higher amounts
        case personality_type
        when "aggressive", "perfectionist"
          adjusted -= 5 if amount < 200_000
        when "pragmatic"
          adjusted += 5 if amount > 100_000
        end
      else # defendant
        # Defendant prefers lower amounts
        case personality_type
        when "aggressive"
          adjusted -= 10 if amount > 150_000
        when "pragmatic"
          adjusted += 5 if amount < 100_000
        end
      end

      # Ensure satisfaction stays within bounds
      adjusted.clamp(0, 100)
    end

    def get_mood_adjustment(personality_type, base_mood, context:)
      case personality_type
      when "emotional"
        case context
        when "positive_offer" then upgrade_mood(base_mood)
        when "negative_offer" then downgrade_mood(base_mood)
        else base_mood
        end
      when "aggressive"
        case context
        when "low_offer" then downgrade_mood(downgrade_mood(base_mood))
        else base_mood
        end
      when "cautious"
        # Cautious personalities are more measured in their responses
        base_mood
      when "pragmatic"
        case context
        when "reasonable_offer" then upgrade_mood(base_mood)
        else base_mood
        end
      when "perfectionist"
        # Perfectionist is harder to please
        case context
        when "positive_offer" then base_mood # Doesn't get as excited
        when "negative_offer" then downgrade_mood(base_mood)
        else base_mood
        end
      else
        base_mood
      end
    end

    def build_personality_prompt(settlement_offer, personality_type, role)
      traits = get_personality_traits(personality_type)
      amount_formatted = ActionController::Base.helpers.number_to_currency(settlement_offer.amount)

      personality_context = build_personality_context(traits, role)

      <<~PROMPT
        You are providing client feedback in a legal education simulation for business law students.

        Context:
        - This is a sexual harassment lawsuit negotiation simulation
        - Team role: #{role}
        - Settlement offer: #{amount_formatted}
        - Client personality: #{traits["name"]} (#{personality_type})

        Client Personality Traits:
        #{traits["traits"].map { |trait| "- #{trait}" }.join("\n")}

        Communication Style:
        - Tone: #{traits["communication_style"]["tone"]}
        - Approach: #{traits["communication_style"]["negotiation_approach"]}

        #{personality_context}

        Please provide realistic client feedback that:
        1. Reflects the client's personality type in language and tone
        2. Uses appropriate language patterns for this personality
        3. Shows personality-consistent emotional response
        4. Provides strategic guidance matching the personality approach
        5. Maintains educational value while being realistic

        Keep the response professional, educational, and under 150 words.
        Use language patterns typical of a #{personality_type} personality.
      PROMPT
    end

    def track_consistency(case_instance, personality_type, responses)
      PersonalityConsistencyTracker.create!(
        case: case_instance,
        personality_type: personality_type,
        response_history: responses,
        consistency_score: calculate_consistency_score(personality_type, responses)
      )
    end

    def validate_personality_consistency(personality_type, previous_responses, new_response)
      traits = get_personality_traits(personality_type)
      expected_patterns = traits["communication_style"]["language_patterns"]

      # Analyze consistency
      all_responses = previous_responses + [new_response]
      consistency_score = calculate_consistency_score(personality_type, all_responses)

      {
        consistent: consistency_score > 60,
        score: consistency_score,
        expected_patterns: expected_patterns,
        analysis: analyze_response_patterns(new_response, expected_patterns)
      }
    end

    private

    def upgrade_mood(mood)
      mood_hierarchy = ["very_unhappy", "unhappy", "neutral", "satisfied", "very_satisfied"]
      current_index = mood_hierarchy.index(mood) || 2
      new_index = [current_index + 1, mood_hierarchy.length - 1].min
      mood_hierarchy[new_index]
    end

    def downgrade_mood(mood)
      mood_hierarchy = ["very_unhappy", "unhappy", "neutral", "satisfied", "very_satisfied"]
      current_index = mood_hierarchy.index(mood) || 2
      new_index = [current_index - 1, 0].max
      mood_hierarchy[new_index]
    end

    def build_personality_context(traits, role)
      case traits["type"]
      when "aggressive"
        "As an aggressive #{role}, express strong dissatisfaction with inadequate offers and make firm demands. Use assertive language and set clear expectations."
      when "cautious"
        "As a cautious #{role}, carefully evaluate the offer's merits and risks. Express measured responses and seek additional information before making decisions."
      when "emotional"
        "As an emotional #{role}, let feelings about the offer show clearly. Express how the offer makes you feel and its emotional impact on the situation."
      when "pragmatic"
        "As a pragmatic #{role}, focus on practical business considerations. Evaluate offers based on realistic outcomes and cost-benefit analysis."
      when "perfectionist"
        "As a perfectionist #{role}, maintain high standards and be critical of offers that don't meet optimal expectations. Express disappointment with subpar proposals."
      else
        "Respond according to your personality type while considering the #{role} perspective."
      end
    end

    def calculate_consistency_score(personality_type, responses)
      return 50 if responses.empty?

      traits = get_personality_traits(personality_type)
      expected_patterns = traits["communication_style"]["language_patterns"]

      # Calculate how many responses contain expected patterns
      pattern_matches = responses.count do |response|
        expected_patterns.any? { |pattern| response.downcase.include?(pattern.downcase) }
      end

      # Base score on pattern matching
      base_score = (pattern_matches.to_f / responses.length * 100).round

      # Adjust for tone consistency
      tone_score = analyze_tone_consistency(responses, traits["communication_style"]["tone"])

      # Average the scores
      ((base_score + tone_score) / 2).round
    end

    def analyze_tone_consistency(responses, expected_tone)
      # Simple tone analysis based on word patterns
      tone_indicators = {
        "assertive" => ["demand", "insist", "must", "require"],
        "demanding" => ["unacceptable", "insufficient", "inadequate"],
        "measured" => ["consider", "evaluate", "thoughtful"],
        "careful" => ["cautious", "prudent", "careful"],
        "expressive" => ["feel", "emotional", "heart"],
        "practical" => ["realistic", "practical", "business"],
        "critical" => ["inadequate", "substandard", "disappointing"]
      }

      expected_tones = expected_tone.split(", ")
      matching_responses = 0

      responses.each do |response|
        response_lower = response.downcase
        has_matching_tone = expected_tones.any? do |tone|
          indicators = tone_indicators[tone] || []
          indicators.any? { |indicator| response_lower.include?(indicator) }
        end
        matching_responses += 1 if has_matching_tone
      end

      return 50 if responses.empty?
      (matching_responses.to_f / responses.length * 100).round
    end

    def analyze_response_patterns(response, expected_patterns)
      found_patterns = expected_patterns.select do |pattern|
        response.downcase.include?(pattern.downcase)
      end

      {
        found_patterns: found_patterns,
        missing_patterns: expected_patterns - found_patterns,
        pattern_coverage: (found_patterns.length.to_f / expected_patterns.length * 100).round
      }
    end
  end
end
