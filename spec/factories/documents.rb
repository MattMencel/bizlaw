# frozen_string_literal: true

FactoryBot.define do
  factory :document do
    association :documentable, factory: :case
    association :created_by, factory: :user
    sequence(:title) { |n| "Document #{n}" }
    description { Faker::Lorem.paragraph }
    file_url { Faker::Internet.url }
    file_type { "pdf" }
    file_size { 1024 }
    document_type { "assignment" }
    status { "draft" }

    after(:build) do |document|
      document.file.attach(
        io: StringIO.new("Test content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
    end

    trait :with_word_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Test content"),
          filename: "test.docx",
          content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        )
      end
    end

    trait :with_excel_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new("Test content"),
          filename: "test.xlsx",
          content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
      end
    end

    trait :template do
      document_type { "template" }
      title { "Template Document" }
    end

    trait :submission do
      document_type { "submission" }
    end

    trait :feedback do
      document_type { "feedback" }
    end

    trait :resource do
      document_type { "resource" }
    end

    trait :final do
      status { "final" }
      finalized_at { Time.current }
    end

    trait :archived do
      status { "archived" }
      archived_at { Time.current }
      after(:create) do |document|
        document.finalize!
        document.archive!
      end
    end

    trait :for_team do
      association :documentable, factory: :team
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end
  end
end
