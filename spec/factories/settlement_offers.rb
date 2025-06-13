# frozen_string_literal: true

FactoryBot.define do
  factory :settlement_offer do
    association :negotiation_round
    association :team
    association :submitted_by, factory: :user

    offer_type { :counteroffer }
    amount { 200000 }
    justification { "This settlement amount reflects the significant damages suffered by our client, including lost wages, emotional distress, and reputational harm. The proposed amount is supported by similar cases and industry standards." }
    non_monetary_terms { "Public apology, implementation of comprehensive harassment training, and policy updates" }
    submitted_at { 1.hour.ago }
    quality_score { nil }

    trait :plaintiff_offer do
      amount { 250000 }
      justification { "Our client has suffered substantial damages including career setbacks, emotional trauma, and ongoing psychological treatment costs. This amount represents fair compensation for the harm caused by the company's failure to address the harassment." }
    end

    trait :defendant_offer do
      amount { 150000 }
      justification { "While we dispute liability, this offer is made in good faith to resolve the matter efficiently. The amount considers the plaintiff's claims while recognizing the disputed nature of the allegations." }
    end

    trait :initial_demand do
      offer_type { :initial_demand }
      amount { 300000 }
    end

    trait :final_offer do
      offer_type { :final_offer }
      amount { 225000 }
    end

    trait :low_amount do
      amount { 75000 }
    end

    trait :high_amount do
      amount { 400000 }
    end

    trait :with_quality_score do
      quality_score { 75.5 }
    end

    trait :poor_justification do
      justification { "This is our offer. Take it or leave it. We think this is fair." }
    end

    trait :excellent_justification do
      justification { "This settlement proposal is based on a comprehensive analysis of similar sexual harassment cases, considering factors including lost wages ($45,000), emotional distress damages ($80,000), punitive damages reflecting the severity of the conduct ($125,000), and attorney fees. The amount aligns with recent verdicts in the jurisdiction while accounting for the strength of the evidence and witness testimony available." }
    end

    trait :creative_terms do
      non_monetary_terms { "Comprehensive sexual harassment training for all employees, establishment of anonymous reporting system, external ombudsman appointment, policy review by employment law expert, public statement on company's commitment to workplace safety" }
    end
  end
end
