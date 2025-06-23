# frozen_string_literal: true

class SimulationDefaultsService
  attr_reader :case_record

  def initialize(case_record)
    @case_record = case_record
  end

  def financial_defaults
    scenario = find_scenario_for_case_type
    return default_financial_parameters unless scenario

    params = scenario[:negotiation_parameters]
    {
      plaintiff_min_acceptable: params[:plaintiff_min_acceptable],
      plaintiff_ideal: params[:plaintiff_ideal],
      defendant_max_acceptable: params[:defendant_max_acceptable],
      defendant_ideal: params[:defendant_ideal],
      total_rounds: params[:total_rounds] || 6
    }
  end

  def randomized_financial_defaults
    base_defaults = financial_defaults
    variation_factor = case_variation_factor

    {
      plaintiff_min_acceptable: randomize_amount(base_defaults[:plaintiff_min_acceptable], variation_factor),
      plaintiff_ideal: randomize_amount(base_defaults[:plaintiff_ideal], variation_factor),
      defendant_max_acceptable: randomize_amount(base_defaults[:defendant_max_acceptable], variation_factor),
      defendant_ideal: randomize_amount(base_defaults[:defendant_ideal], variation_factor),
      total_rounds: base_defaults[:total_rounds]
    }.tap do |params|
      ensure_mathematical_validity!(params)
    end
  end

  def default_teams
    plaintiff_team = find_or_create_team(:plaintiff)
    defendant_team = find_or_create_team(:defendant)

    {
      plaintiff_team: plaintiff_team,
      defendant_team: defendant_team
    }
  end

  def build_simulation_with_defaults
    defaults = financial_defaults
    teams = default_teams

    Simulation.new(
      case: case_record,
      plaintiff_min_acceptable: defaults[:plaintiff_min_acceptable],
      plaintiff_ideal: defaults[:plaintiff_ideal],
      defendant_max_acceptable: defaults[:defendant_max_acceptable],
      defendant_ideal: defaults[:defendant_ideal],
      total_rounds: defaults[:total_rounds],
      current_round: 1,
      status: :setup,
      pressure_escalation_rate: :moderate,
      plaintiff_team: teams[:plaintiff_team],
      defendant_team: teams[:defendant_team],
      simulation_config: default_simulation_config
    )
  end

  def build_simulation_with_randomized_defaults
    defaults = randomized_financial_defaults
    teams = default_teams

    Simulation.new(
      case: case_record,
      plaintiff_min_acceptable: defaults[:plaintiff_min_acceptable],
      plaintiff_ideal: defaults[:plaintiff_ideal],
      defendant_max_acceptable: defaults[:defendant_max_acceptable],
      defendant_ideal: defaults[:defendant_ideal],
      total_rounds: defaults[:total_rounds],
      current_round: 1,
      status: :setup,
      pressure_escalation_rate: :moderate,
      plaintiff_team: teams[:plaintiff_team],
      defendant_team: teams[:defendant_team],
      simulation_config: default_simulation_config
    )
  end

  private

  def find_scenario_for_case_type
    return nil if case_record.case_type.blank?

    CaseScenarioService.all.find do |scenario|
      scenario[:case_type] == case_record.case_type
    end
  end

  def default_financial_parameters
    {
      plaintiff_min_acceptable: 150_000,
      plaintiff_ideal: 300_000,
      defendant_max_acceptable: 250_000,
      defendant_ideal: 75_000,
      total_rounds: 6
    }
  end

  def case_variation_factor
    case case_record.case_type&.to_sym
    when :intellectual_property
      0.5  # High-value cases get more variation
    when :discrimination, :sexual_harassment
      0.3  # Standard variation
    when :contract_dispute, :wrongful_termination
      0.4  # Moderate variation
    else
      0.3  # Default variation
    end
  end

  def randomize_amount(base_amount, variation_factor)
    min_variation = 1.0 - variation_factor
    max_variation = 1.0 + variation_factor
    variation = rand(min_variation..max_variation)
    (base_amount * variation).round
  end

  def ensure_mathematical_validity!(params)
    # Ensure plaintiff_min <= plaintiff_ideal
    if params[:plaintiff_min_acceptable] > params[:plaintiff_ideal]
      params[:plaintiff_min_acceptable] = (params[:plaintiff_ideal] * 0.8).round
    end

    # Ensure defendant_ideal <= defendant_max
    if params[:defendant_ideal] > params[:defendant_max_acceptable]
      params[:defendant_ideal] = (params[:defendant_max_acceptable] * 0.5).round
    end

    # Ensure settlement is possible: plaintiff_min <= defendant_max
    if params[:plaintiff_min_acceptable] > params[:defendant_max_acceptable]
      overlap_point = (params[:plaintiff_min_acceptable] + params[:defendant_max_acceptable]) / 2
      params[:plaintiff_min_acceptable] = overlap_point - 10_000
      params[:defendant_max_acceptable] = overlap_point + 10_000
    end
  end

  def find_or_create_team(role)
    existing_team = case_record.case_teams.find_by(role: role)&.team
    return existing_team if existing_team

    create_team_for_role(role)
  end

  def create_team_for_role(role)
    team_name = (role == :plaintiff) ? "Plaintiff Team" : "Defendant Team"
    description = (role == :plaintiff) ? "Default team for plaintiff side" : "Default team for defendant side"

    # Ensure owner is enrolled in the course
    unless case_record.course.course_enrollments.exists?(user: case_record.created_by, status: "active")
      case_record.course.course_enrollments.create!(user: case_record.created_by, status: "active")
    end

    team = Team.create!(
      name: team_name,
      description: description,
      course: case_record.course,
      max_members: 10,
      owner: case_record.created_by
    )

    case_record.case_teams.create!(
      team: team,
      role: role
    )

    team
  end

  def default_simulation_config
    {
      "client_mood_enabled" => "true",
      "pressure_escalation_enabled" => "true",
      "auto_round_advancement" => "false",
      "settlement_range_hints" => "false",
      "arbitration_threshold_rounds" => "5",
      "round_duration_hours" => "48"
    }
  end
end
