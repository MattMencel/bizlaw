# frozen_string_literal: true

FactoryBot.define do
  factory :case_event do
    association :case
    association :user
    event_type { :created }
    data { { action: 'test_action', details: 'test details' } }

    trait :created do
      event_type { :created }
      data do
        {
          case_title: 'Test Case',
          created_by: 'Test User',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :updated do
      event_type { :updated }
      data do
        {
          changes: {
            title: [ 'Old Title', 'New Title' ],
            status: [ 'draft', 'published' ]
          },
          updated_by: 'Test User',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :status_changed do
      event_type { :status_changed }
      data do
        {
          previous_status: 'draft',
          new_status: 'published',
          changed_by: 'Test User',
          reason: 'Case ready for publication',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :document_added do
      event_type { :document_added }
      data do
        {
          document_id: SecureRandom.uuid,
          document_name: 'test_document.pdf',
          document_type: 'evidence',
          added_by: 'Test User',
          file_size: 1024,
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :document_removed do
      event_type { :document_removed }
      data do
        {
          document_id: SecureRandom.uuid,
          document_name: 'removed_document.pdf',
          removed_by: 'Test User',
          reason: 'No longer relevant',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :team_member_added do
      event_type { :team_member_added }
      data do
        {
          team_id: SecureRandom.uuid,
          team_name: 'Test Team',
          user_id: SecureRandom.uuid,
          user_name: 'New Team Member',
          role: 'plaintiff',
          added_by: 'Test User',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :team_member_removed do
      event_type { :team_member_removed }
      data do
        {
          team_id: SecureRandom.uuid,
          team_name: 'Test Team',
          user_id: SecureRandom.uuid,
          user_name: 'Removed Team Member',
          role: 'defendant',
          removed_by: 'Test User',
          reason: 'Left the course',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :comment_added do
      event_type { :comment_added }
      data do
        {
          comment_id: SecureRandom.uuid,
          comment_text: 'This is a test comment on the case',
          commented_by: 'Test User',
          visibility: 'public',
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :with_metadata do
      data do
        {
          action: 'test_action',
          details: 'test details',
          metadata: {
            ip_address: '192.168.1.1',
            user_agent: 'Test Browser 1.0',
            session_id: SecureRandom.hex(16),
            request_id: SecureRandom.uuid
          },
          timestamp: Time.current.iso8601
        }
      end
    end

    trait :with_complex_data do
      data do
        {
          primary_action: 'complex_case_update',
          changes: {
            plaintiff_info: {
              old: { name: 'Old Plaintiff', type: 'individual' },
              new: { name: 'New Plaintiff Corp', type: 'corporation' }
            },
            defendant_info: {
              old: { name: 'Old Defendant', type: 'corporation' },
              new: { name: 'New Defendant LLC', type: 'llc' }
            },
            legal_issues: {
              added: [ 'discrimination', 'wrongful_termination' ],
              removed: [ 'harassment' ]
            }
          },
          performance_metrics: {
            processing_time_ms: 150,
            database_queries: 12,
            cache_hits: 8
          },
          audit_trail: {
            reviewed_by: 'system',
            compliance_check: 'passed',
            approval_required: false
          }
        }
      end
    end
  end
end
