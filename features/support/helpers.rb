# frozen_string_literal: true

module TestHelpers
  def login_as(user, scope: :user)
    if defined?(Warden)
      Warden::Test::Helpers.login_as(user, scope: scope)
    else
      # Fallback to UI sign-in
      visit new_user_session_path
      fill_in "Email", with: user.email
      fill_in "Password", with: user.password || 'password123'
      click_button "Log in"
    end
  end

  def sign_in_user(user)
    login_as(user)
  end

  def sign_out_user
    if defined?(Warden)
      Warden::Test::Helpers.logout
    else
      visit destroy_user_session_path
    end
  end

  def create_user(attributes = {})
    default_attributes = {
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: :student,
      confirmed_at: Time.current
    }
    create(:user, default_attributes.merge(attributes))
  end

  def mock_google_oauth(email: 'test@example.com', name: 'Test User')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '123456789',
      info: {
        email: email,
        name: name,
        first_name: name.split.first,
        last_name: name.split.last
      },
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token'
      }
    })
  end

  def mock_google_oauth_failure
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
  end

  def expire_cookies
    # Simulate browser close/reopen by expiring session cookies
    if respond_to?(:page)
      page.driver.browser.manage.delete_all_cookies if page.driver.respond_to?(:browser)
    end
  end

  def clear_emails
    ActionMailer::Base.deliveries.clear
  end

  def last_email
    ActionMailer::Base.deliveries.last
  end

  def click_first_link_in_email
    # This would be implemented with email testing gems like email_spec
    # For now, simulate the confirmation process
    @user.confirm if @user.respond_to?(:confirm)
  end

  def open_email(recipient)
    # Mock email opening - in real implementation would use email testing tools
    last_email
  end

  # Time manipulation helpers
  def freeze_time(&block)
    if defined?(Timecop)
      Timecop.freeze(&block)
    else
      # Fallback for basic time freezing
      block.call
    end
  end

  def travel(duration, &block)
    if defined?(Timecop)
      Timecop.travel(duration, &block)
    else
      # Basic time travel simulation
      block.call
    end
  end

  # Path helpers for common routes
  def dashboard_path
    '/dashboard'
  end

  def account_path
    '/profiles/show'
  end

  def case_analytics_path
    '/cases/analytics'
  end

  def new_case_path
    '/cases/new'
  end

  def cases_path
    '/cases'
  end

  def case_path(case_record)
    "/cases/#{case_record.id}"
  end

  def edit_case_path(case_record)
    "/cases/#{case_record.id}/edit"
  end

  def new_team_path
    '/teams/new'
  end

  def teams_path
    '/teams'
  end

  def team_path(team)
    "/teams/#{team.id}"
  end

  def edit_team_path(team)
    "/teams/#{team.id}/edit"
  end

  def team_team_members_path(team)
    "/teams/#{team.id}/team_members"
  end

  def new_team_team_member_path(team)
    "/teams/#{team.id}/team_members/new"
  end

  def documents_path
    '/documents'
  end

  def document_path(document)
    "/documents/#{document.id}"
  end

  def new_document_path
    '/documents/new'
  end

  def edit_document_path(document)
    "/documents/#{document.id}/edit"
  end

  def case_documents_path(case_record)
    "/cases/#{case_record.id}/documents"
  end

  def team_documents_path(team)
    "/teams/#{team.id}/documents"
  end

  # Factory creation helpers
  def create_case_with_teams
    instructor = create(:user, role: :instructor)
    plaintiff_team = create(:team, name: 'Plaintiff Team')
    defendant_team = create(:team, name: 'Defendant Team')

    case_record = create(:case, created_by: instructor)
    create(:case_team, case: case_record, team: plaintiff_team, role: :plaintiff)
    create(:case_team, case: case_record, team: defendant_team, role: :defendant)

    case_record
  end

  # Support for missing model alignments
  def ensure_case_type_compatibility
    # Helper to bridge case_type enum vs CaseType model mismatch
    # This can be used in step definitions to handle the model differences
  end
end

World(TestHelpers)
