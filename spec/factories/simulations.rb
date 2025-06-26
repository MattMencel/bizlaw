# frozen_string_literal: true

FactoryBot.define do
  factory :simulation do
    association :case
    start_date { nil } # Only set when active
    end_date { nil }
    total_rounds { 6 }
    current_round { 1 }
    status { :setup }
    plaintiff_min_acceptable { nil } # Only required when active
    plaintiff_ideal { nil } # Only required when active
    defendant_max_acceptable { nil } # Only required when active
    defendant_ideal { nil } # Only required when active
    pressure_escalation_rate { :moderate }
    simulation_config { {auto_events: true, scoring_enabled: true} }
    auto_events_enabled { true }
    argument_quality_required { true }

    trait :with_teams do
      after(:create) do |simulation|
        create(:team, simulation: simulation, role: :plaintiff)
        create(:team, simulation: simulation, role: :defendant)
      end
    end

    trait :active do
      status { :active }
      start_date { 1.hour.ago }
      plaintiff_min_acceptable { 150000 }
      plaintiff_ideal { 300000 }
      defendant_max_acceptable { 250000 }
      defendant_ideal { 75000 }

      after(:create) do |simulation|
        create(:team, simulation: simulation, role: :plaintiff) unless simulation.plaintiff_teams.exists?
        create(:team, simulation: simulation, role: :defendant) unless simulation.defendant_teams.exists?
      end
    end

    trait :completed do
      status { :completed }
      start_date { 1.week.ago }
      end_date { 1.day.ago }
      current_round { 6 }
      plaintiff_min_acceptable { 150000 }
      plaintiff_ideal { 300000 }
      defendant_max_acceptable { 250000 }
      defendant_ideal { 75000 }

      after(:create) do |simulation|
        create(:team, simulation: simulation, role: :plaintiff) unless simulation.plaintiff_teams.exists?
        create(:team, simulation: simulation, role: :defendant) unless simulation.defendant_teams.exists?
      end
    end

    trait :arbitration do
      status { :arbitration }
      start_date { 1.week.ago }
      end_date { 1.day.ago }
      current_round { 6 }
      plaintiff_min_acceptable { 150000 }
      plaintiff_ideal { 300000 }
      defendant_max_acceptable { 250000 }
      defendant_ideal { 75000 }

      after(:create) do |simulation|
        create(:team, simulation: simulation, role: :plaintiff) unless simulation.plaintiff_teams.exists?
        create(:team, simulation: simulation, role: :defendant) unless simulation.defendant_teams.exists?
      end
    end

    trait :paused do
      status { :paused }
      start_date { 1.hour.ago }
      plaintiff_min_acceptable { 150000 }
      plaintiff_ideal { 300000 }
      defendant_max_acceptable { 250000 }
      defendant_ideal { 75000 }

      after(:create) do |simulation|
        create(:team, simulation: simulation, role: :plaintiff) unless simulation.plaintiff_teams.exists?
        create(:team, simulation: simulation, role: :defendant) unless simulation.defendant_teams.exists?
      end
    end

    trait :high_pressure do
      pressure_escalation_rate { :high }
    end

    trait :low_pressure do
      pressure_escalation_rate { :low }
    end

    trait :named do
      name { "Custom Simulation Name" }
    end

    trait :midterm do
      name { "Midterm Practice" }
    end

    trait :final do
      name { "Final Negotiation" }
    end
  end
end
