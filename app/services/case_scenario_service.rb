# frozen_string_literal: true

class CaseScenarioService
  SCENARIOS = [
    # Sexual Harassment Cases
    {
      id: "mitchell_v_techflow",
      title: "Mitchell v. TechFlow Industries",
      description: "Sexual harassment lawsuit involving workplace misconduct allegations between a software engineer and her employer",
      case_type: "sexual_harassment",
      difficulty_level: "intermediate",
      legal_issues: "Sexual harassment, hostile work environment, retaliation claims",
      plaintiff_info: {
        name: "Sarah Mitchell",
        position: "Software Engineer",
        employment_duration: "3 years",
        background: "Experienced software engineer with strong performance record"
      },
      defendant_info: {
        name: "TechFlow Industries",
        type: "Corporation",
        industry: "Software Development",
        size: "Mid-sized company (~200 employees)",
        background: "Growing tech company preparing for IPO"
      },
      reference_number: "CASE-2024-001",
      negotiation_parameters: {
        plaintiff_min_acceptable: 150000,
        plaintiff_ideal: 300000,
        defendant_max_acceptable: 250000,
        defendant_ideal: 75000,
        total_rounds: 6
      },
      simulation_config: {
        event_probabilities: {
          media_attention: {
            base_probability: 0.6,
            case_type_modifiers: {"sexual_harassment" => 1.3}
          },
          witness_change: {
            base_probability: 0.5,
            gap_based_triggering: true,
            gap_threshold_factor: 0.3,
            large_gap_probability: 0.7,
            small_gap_probability: 0.4
          },
          ipo_delay: {
            base_probability: 0.55,
            case_type_modifiers: {"sexual_harassment" => 1.2}
          },
          court_deadline: {
            base_probability: 0.8,
            round_escalation: true,
            round_escalation_factor: 1.1
          }
        },
        round_triggers: {
          "2" => {"media_attention" => true},
          "3" => {"witness_change" => true},
          "4" => {"ipo_delay" => true},
          "5" => {"court_deadline" => true}
        }
      }
    },

    # Contract Dispute Cases
    {
      id: "apex_v_digitech",
      title: "Apex Solutions v. DigiTech Corp",
      description: "Breach of software development contract involving missed deadlines and scope changes",
      case_type: "contract_dispute",
      difficulty_level: "intermediate",
      legal_issues: "Breach of contract, scope creep, liquidated damages, force majeure",
      plaintiff_info: {
        name: "Apex Solutions LLC",
        type: "Contractor",
        industry: "Software Development",
        background: "Small consulting firm specializing in enterprise software"
      },
      defendant_info: {
        name: "DigiTech Corp",
        type: "Corporation",
        industry: "Financial Services",
        size: "Large company (500+ employees)",
        background: "Established financial services company with complex IT needs"
      },
      reference_number: "CASE-2024-002",
      negotiation_parameters: {
        plaintiff_min_acceptable: 85000,
        plaintiff_ideal: 175000,
        defendant_max_acceptable: 125000,
        defendant_ideal: 35000,
        total_rounds: 6
      },
      simulation_config: {
        event_probabilities: {
          media_attention: {
            base_probability: 0.3,
            case_type_modifiers: {"contract_dispute" => 0.5}
          },
          witness_change: {
            base_probability: 0.6,
            gap_based_triggering: true,
            gap_threshold_factor: 0.4,
            large_gap_probability: 0.8,
            small_gap_probability: 0.5
          },
          ipo_delay: {
            base_probability: 0.2,
            case_type_modifiers: {"contract_dispute" => 0.3}
          },
          court_deadline: {
            base_probability: 0.9,
            round_escalation: true,
            round_escalation_factor: 1.15
          }
        },
        round_triggers: {
          "2" => {"witness_change" => true},
          "3" => {"media_attention" => true},
          "4" => {"court_deadline" => true},
          "5" => {"court_deadline" => true}
        }
      }
    },

    # Discrimination Cases
    {
      id: "chen_v_globalbank",
      title: "Chen v. Global Bank Holdings",
      description: "Age discrimination lawsuit involving wrongful termination and promotion denial",
      case_type: "discrimination",
      difficulty_level: "advanced",
      legal_issues: "Age discrimination, wrongful termination, disparate treatment, pattern of bias",
      plaintiff_info: {
        name: "Robert Chen",
        position: "Senior Vice President",
        employment_duration: "12 years",
        background: "Veteran banking executive with excellent performance record"
      },
      defendant_info: {
        name: "Global Bank Holdings",
        type: "Corporation",
        industry: "Banking",
        size: "Large corporation (10,000+ employees)",
        background: "Major financial institution with recent restructuring initiatives"
      },
      reference_number: "CASE-2024-003",
      negotiation_parameters: {
        plaintiff_min_acceptable: 200000,
        plaintiff_ideal: 450000,
        defendant_max_acceptable: 350000,
        defendant_ideal: 125000,
        total_rounds: 6
      },
      simulation_config: {
        event_probabilities: {
          media_attention: {
            base_probability: 0.7,
            case_type_modifiers: {"discrimination" => 1.2}
          },
          witness_change: {
            base_probability: 0.4,
            gap_based_triggering: true,
            gap_threshold_factor: 0.25,
            large_gap_probability: 0.6,
            small_gap_probability: 0.3
          },
          ipo_delay: {
            base_probability: 0.15,
            case_type_modifiers: {"discrimination" => 0.2}
          },
          court_deadline: {
            base_probability: 0.85,
            round_escalation: true,
            round_escalation_factor: 1.12
          }
        },
        round_triggers: {
          "2" => {"media_attention" => true},
          "3" => {"witness_change" => true},
          "4" => {"court_deadline" => true},
          "5" => {"court_deadline" => true}
        }
      }
    },

    # Intellectual Property Cases
    {
      id: "innovate_v_techgiant",
      title: "Innovate Labs v. TechGiant Inc",
      description: "Patent infringement lawsuit involving machine learning algorithms and trade secrets",
      case_type: "intellectual_property",
      difficulty_level: "advanced",
      legal_issues: "Patent infringement, trade secret misappropriation, injunctive relief, royalty disputes",
      plaintiff_info: {
        name: "Innovate Labs Inc",
        type: "Technology Startup",
        industry: "Artificial Intelligence",
        background: "AI research company with 15 patents in machine learning"
      },
      defendant_info: {
        name: "TechGiant Inc",
        type: "Corporation",
        industry: "Technology",
        size: "Large corporation (50,000+ employees)",
        background: "Major technology company with extensive R&D operations"
      },
      reference_number: "CASE-2024-004",
      negotiation_parameters: {
        plaintiff_min_acceptable: 2500000,
        plaintiff_ideal: 8000000,
        defendant_max_acceptable: 5500000,
        defendant_ideal: 1200000,
        total_rounds: 8
      },
      simulation_config: {
        event_probabilities: {
          media_attention: {
            base_probability: 0.8,
            case_type_modifiers: {"intellectual_property" => 1.4}
          },
          witness_change: {
            base_probability: 0.7,
            gap_based_triggering: true,
            gap_threshold_factor: 0.35,
            large_gap_probability: 0.9,
            small_gap_probability: 0.6
          },
          ipo_delay: {
            base_probability: 0.4,
            case_type_modifiers: {"intellectual_property" => 0.8}
          },
          court_deadline: {
            base_probability: 0.75,
            round_escalation: true,
            round_escalation_factor: 1.08
          }
        },
        round_triggers: {
          "2" => {"media_attention" => true},
          "3" => {"witness_change" => true},
          "4" => {"ipo_delay" => true},
          "5" => {"court_deadline" => true},
          "6" => {"court_deadline" => true},
          "7" => {"court_deadline" => true}
        }
      }
    },

    # Wrongful Termination Cases
    {
      id: "martinez_v_retailcorp",
      title: "Martinez v. RetailCorp Systems",
      description: "Wrongful termination lawsuit involving whistleblower retaliation and breach of employment contract",
      case_type: "wrongful_termination",
      difficulty_level: "intermediate",
      legal_issues: "Wrongful termination, whistleblower retaliation, breach of contract, emotional distress",
      plaintiff_info: {
        name: "Maria Martinez",
        position: "Operations Manager",
        employment_duration: "7 years",
        background: "Dedicated employee who reported safety violations before termination"
      },
      defendant_info: {
        name: "RetailCorp Systems",
        type: "Corporation",
        industry: "Retail Technology",
        size: "Medium company (1,000 employees)",
        background: "Retail technology company facing regulatory scrutiny"
      },
      reference_number: "CASE-2024-005",
      negotiation_parameters: {
        plaintiff_min_acceptable: 125000,
        plaintiff_ideal: 275000,
        defendant_max_acceptable: 200000,
        defendant_ideal: 65000,
        total_rounds: 6
      },
      simulation_config: {
        event_probabilities: {
          media_attention: {
            base_probability: 0.5,
            case_type_modifiers: {"wrongful_termination" => 1.1}
          },
          witness_change: {
            base_probability: 0.55,
            gap_based_triggering: true,
            gap_threshold_factor: 0.3,
            large_gap_probability: 0.75,
            small_gap_probability: 0.45
          },
          ipo_delay: {
            base_probability: 0.25,
            case_type_modifiers: {"wrongful_termination" => 0.4}
          },
          court_deadline: {
            base_probability: 0.8,
            round_escalation: true,
            round_escalation_factor: 1.1
          }
        },
        round_triggers: {
          "2" => {"media_attention" => true},
          "3" => {"witness_change" => true},
          "4" => {"court_deadline" => true},
          "5" => {"court_deadline" => true}
        }
      }
    }
  ].freeze

  def self.all
    SCENARIOS
  end

  def self.find(id)
    SCENARIOS.find { |scenario| scenario[:id] == id }
  end

  def self.build_case_from_scenario(scenario_id, course:, created_by:)
    scenario = find(scenario_id)
    return nil unless scenario

    Case.new(
      title: scenario[:title],
      description: scenario[:description],
      case_type: scenario[:case_type],
      difficulty_level: scenario[:difficulty_level],
      legal_issues: scenario[:legal_issues].is_a?(String) ? [scenario[:legal_issues]] : scenario[:legal_issues],
      plaintiff_info: scenario[:plaintiff_info],
      defendant_info: scenario[:defendant_info],
      reference_number: generate_reference_number,
      course: course,
      created_by: created_by,
      updated_by: created_by,
      status: "not_started"
    )
  end

  def self.build_simulation_from_scenario(scenario_id, case_record:)
    scenario = find(scenario_id)
    return nil unless scenario

    params = scenario[:negotiation_parameters]
    config = scenario[:simulation_config] || {}

    Simulation.new(
      case: case_record,
      start_date: Time.current,
      total_rounds: params[:total_rounds] || 6,
      plaintiff_min_acceptable: params[:plaintiff_min_acceptable],
      plaintiff_ideal: params[:plaintiff_ideal],
      defendant_max_acceptable: params[:defendant_max_acceptable],
      defendant_ideal: params[:defendant_ideal],
      simulation_config: config,
      status: "setup"
    )
  end

  def self.by_case_type(case_type)
    SCENARIOS.select { |scenario| scenario[:case_type] == case_type }
  end

  def self.case_types
    SCENARIOS.distinct.pluck(:case_type)
  end

  def self.difficulty_levels
    SCENARIOS.distinct.pluck(:difficulty_level)
  end

  private

  def self.generate_reference_number
    "CASE-#{Date.current.year}-#{SecureRandom.hex(3).upcase}"
  end
end
