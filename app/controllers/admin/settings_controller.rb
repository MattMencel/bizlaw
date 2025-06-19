# frozen_string_literal: true

class Admin::SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_settings_category, only: [:show, :update]

  def index
    @settings_categories = {
      "general" => "General Settings",
      "security" => "Security & Authentication",
      "email" => "Email Configuration",
      "features" => "Feature Flags",
      "integrations" => "External Integrations"
    }
  end

  def show
    @category = params[:id]
    @settings = load_settings_for_category(@category)

    unless @settings
      redirect_to admin_settings_path, alert: "Invalid settings category"
      nil
    end
  end

  def update
    @category = params[:id]
    @settings = load_settings_for_category(@category)

    unless @settings
      redirect_to admin_settings_path, alert: "Invalid settings category"
      return
    end

    if update_settings_for_category(@category, settings_params)
      redirect_to admin_settings_path, notice: "Settings updated successfully"
    else
      flash.now[:alert] = "Failed to update settings. Please check the form for errors."
      render :show
    end
  end

  private

  def ensure_admin!
    unless current_user.admin? || current_user.roles.include?("admin")
      render file: Rails.public_path.join("403.html"), status: :forbidden
    end
  end

  def set_settings_category
    @valid_categories = %w[general security email features integrations]
    unless @valid_categories.include?(params[:id])
      redirect_to admin_settings_path, alert: "Invalid settings category"
    end
  end

  def load_settings_for_category(category)
    case category
    when "general"
      {
        application_name: ENV.fetch("APPLICATION_NAME", "Business Law Education Platform"),
        maintenance_mode: ENV.fetch("MAINTENANCE_MODE", "false") == "true",
        registration_enabled: ENV.fetch("REGISTRATION_ENABLED", "true") == "true",
        contact_email: ENV.fetch("CONTACT_EMAIL", "support@example.com"),
        support_url: ENV.fetch("SUPPORT_URL", "")
      }
    when "security"
      {
        session_timeout: ENV.fetch("SESSION_TIMEOUT_MINUTES", "120").to_i,
        password_complexity: ENV.fetch("PASSWORD_COMPLEXITY", "medium"),
        two_factor_required: ENV.fetch("TWO_FACTOR_REQUIRED", "false") == "true",
        login_attempts_limit: ENV.fetch("LOGIN_ATTEMPTS_LIMIT", "5").to_i
      }
    when "email"
      {
        smtp_host: ENV.fetch("SMTP_HOST", ""),
        smtp_port: ENV.fetch("SMTP_PORT", "587").to_i,
        smtp_username: ENV.fetch("SMTP_USERNAME", ""),
        smtp_use_tls: ENV.fetch("SMTP_USE_TLS", "true") == "true",
        from_email: ENV.fetch("FROM_EMAIL", "noreply@example.com")
      }
    when "features"
      {
        evidence_vault_enabled: ENV.fetch("EVIDENCE_VAULT_ENABLED", "true") == "true",
        negotiations_enabled: ENV.fetch("NEGOTIATIONS_ENABLED", "true") == "true",
        real_time_updates: ENV.fetch("REAL_TIME_UPDATES", "true") == "true",
        file_upload_enabled: ENV.fetch("FILE_UPLOAD_ENABLED", "true") == "true",
        advanced_analytics: ENV.fetch("ADVANCED_ANALYTICS", "false") == "true"
      }
    when "integrations"
      {
        google_oauth_enabled: ENV.fetch("GOOGLE_OAUTH_ENABLED", "false") == "true",
        slack_notifications: ENV.fetch("SLACK_NOTIFICATIONS", "false") == "true",
        webhook_url: ENV.fetch("WEBHOOK_URL", ""),
        api_rate_limit: ENV.fetch("API_RATE_LIMIT", "1000").to_i
      }
    end
  end

  def update_settings_for_category(category, params)
    # In a real application, you would update these settings in a database
    # or configuration management system. For now, we'll simulate success.

    # Validate the settings based on category
    case category
    when "general"
      return false if params[:application_name].blank?
      return false if params[:contact_email].present? && !params[:contact_email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    when "security"
      return false if params[:session_timeout].to_i < 5 || params[:session_timeout].to_i > 1440
      return false if params[:login_attempts_limit].to_i < 1 || params[:login_attempts_limit].to_i > 20
    when "email"
      return false if params[:smtp_host].present? && params[:smtp_port].to_i <= 0
      return false if params[:from_email].present? && !params[:from_email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
    end

    # Log the settings update for audit purposes
    Rails.logger.info "Admin #{current_user.email} updated #{category} settings: #{params.inspect}"

    # Return true to indicate successful update
    true
  end

  def settings_params
    case params[:id]
    when "general"
      params.require(:settings).permit(:application_name, :maintenance_mode, :registration_enabled, :contact_email, :support_url)
    when "security"
      params.require(:settings).permit(:session_timeout, :password_complexity, :two_factor_required, :login_attempts_limit)
    when "email"
      params.require(:settings).permit(:smtp_host, :smtp_port, :smtp_username, :smtp_use_tls, :from_email)
    when "features"
      params.require(:settings).permit(:evidence_vault_enabled, :negotiations_enabled, :real_time_updates, :file_upload_enabled, :advanced_analytics)
    when "integrations"
      params.require(:settings).permit(:google_oauth_enabled, :slack_notifications, :webhook_url, :api_rate_limit)
    else
      {}
    end
  end
end
