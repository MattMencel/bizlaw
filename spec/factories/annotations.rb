FactoryBot.define do
  factory :annotation do
    content { "MyText" }
    document { nil }
    user { nil }
    x_position { "9.99" }
    y_position { "9.99" }
    page_number { 1 }
  end
end
