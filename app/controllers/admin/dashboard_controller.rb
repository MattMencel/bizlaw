# frozen_string_literal: true

class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @stats = gather_dashboard_stats
    @recent_activity = gather_recent_activity
    @system_status = gather_system_status
  end

  private

  def ensure_admin!
    unless current_user.admin? || current_user.roles.include?("admin")
      render file: Rails.root.join("public", "403.html"), status: :forbidden
    end
  end

  def gather_dashboard_stats
    {
      total_users: User.count,
      total_organizations: Organization.count,
      total_cases: Case.count,
      total_teams: Team.count,
      active_users_today: User.where("last_sign_in_at >= ?", 1.day.ago).count,
      new_users_this_week: User.where("created_at >= ?", 1.week.ago).count,
      active_cases: Case.active.count,
      licenses_active: License.where(active: true).count
    }
  end

  def gather_recent_activity
    # Get recent user registrations and case creations
    recent_users = User.order(created_at: :desc).limit(5).pluck(:email, :created_at, :role)
    recent_cases = Case.order(created_at: :desc).limit(5).includes(:course).pluck(:title, :created_at, :'courses.title')

    {
      recent_users: recent_users.map { |email, created_at, role|
        { email: email, created_at: created_at, role: role }
      },
      recent_cases: recent_cases.map { |title, created_at, course_name|
        { title: title, created_at: created_at, course_name: course_name }
      }
    }
  end

  def gather_system_status
    {
      database_status: check_database_status,
      cache_status: check_cache_status,
      storage_status: check_storage_status,
      email_status: check_email_status
    }
  end

  def check_database_status
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      { status: "healthy", message: "Database connection successful" }
    rescue => e
      { status: "error", message: "Database error: #{e.message}" }
    end
  end

  def check_cache_status
    begin
      Rails.cache.write("health_check", Time.current)
      cached_time = Rails.cache.read("health_check")
      if cached_time
        { status: "healthy", message: "Cache read/write successful" }
      else
        { status: "warning", message: "Cache write successful but read failed" }
      end
    rescue => e
      { status: "error", message: "Cache error: #{e.message}" }
    end
  end

  def check_storage_status
    begin
      # Check if we can write to the storage directory
      temp_file = Rails.root.join("tmp", "storage_check.tmp")
      File.write(temp_file, "health check")
      File.delete(temp_file) if File.exist?(temp_file)
      { status: "healthy", message: "Storage read/write successful" }
    rescue => e
      { status: "error", message: "Storage error: #{e.message}" }
    end
  end

  def check_email_status
    begin
      # Simple check to see if SMTP settings are configured
      if ActionMailer::Base.smtp_settings.present? && ActionMailer::Base.smtp_settings[:address].present?
        { status: "healthy", message: "Email configuration present" }
      else
        { status: "warning", message: "Email not configured" }
      end
    rescue => e
      { status: "error", message: "Email configuration error: #{e.message}" }
    end
  end
end
