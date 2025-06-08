require "dotenv/load" if defined?(Dotenv)

# frozen_string_literal: true

# Assuming you have not yet modified this file, each configuration option below
# is set to its default value. Note that some are commented out while others
# are not: uncommented lines are intended to protect your configuration from
# breaking changes in upgrades (i.e., in the event that future versions of
# Devise change the default values for those options).
#
# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  # The secret key used by Devise. Devise uses this key to generate
  # random tokens. Changing this key will render invalid all existing
  # confirmation, reset password and unlock tokens in the database.
  # Devise will use the `secret_key_base` as its `secret_key`
  # by default. You can change it below and use your own secret key.
  config.secret_key = Rails.application.credentials.secret_key_base

  # ==> Controller configuration
  # Configure the parent class to the devise controllers.
  config.parent_controller = "ApplicationController"

  # ==> Mailer Configuration
  # Configure the e-mail address which will be shown in Devise::Mailer,
  # note that it will be overwritten if you use your own mailer class
  # with default "from" parameter.
  config.mailer_sender = ENV.fetch("MAILER_FROM", "noreply@bizlaw.app")

  # Configure the class responsible to send e-mails.
  # config.mailer = "Devise::Mailer"

  # Configure the parent class responsible to send e-mails.
  # config.parent_mailer = "ActionMailer::Base"

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require "devise/orm/active_record"

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  config.authentication_keys = [:email]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [:email]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [:email]

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again.
  config.timeout_in = 30.minutes

  # ==> Configuration for :validatable
  # Range for password length.
  config.password_length = 6..128

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  config.navigational_formats = [:html]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = [:delete, :get]

  # ==> OmniAuth
  # Add a new OAuth provider. For example, the following would add Google OAuth2:

  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    puts "[DEBUG] Inside OmniAuth provider block"
    Rails.logger.info "[Devise] Google OmniAuth provider enabled."
    config.omniauth :google_oauth2,
      ENV["GOOGLE_CLIENT_ID"],
      ENV["GOOGLE_CLIENT_SECRET"],
      {
        scope: "email,profile"
      }
  else
    puts "[DEBUG] OmniAuth provider block NOT enabled"
    Rails.logger.warn "[Devise] GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET is missing. Google OmniAuth provider NOT enabled."
  end

  # ==> JWT Configuration
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.secret_key_base
    jwt.dispatch_requests = [
      ["POST", %r{^/api/login$}],
      ["POST", %r{^/api/signup$}],
      ["POST", %r{^/users/auth/google_oauth2/callback$}]
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/api/logout$}]
    ]
    jwt.expiration_time = 1.hour
  end

  # ==> Hotwire/Turbo configuration
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # ==> Configuration for :registerable
  # When set to false, does not sign a user in automatically after their password is
  # changed. Defaults to true, so a user is signed in automatically after changing a password.
  config.sign_in_after_change_password = false

  # ==> Security Configuration
  # Force user to reauthenticate before accessing sensitive areas
  config.reconfirmable = true

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  config.skip_session_storage = [:http_auth]

  # ==> Configuration for :database_authenticatable
  config.stretches = Rails.env.test? ? 1 : 12

  # ==> Configuration for :rememberable
  config.remember_for = 2.weeks
  config.expire_all_remember_me_on_sign_out = true

  # ==> Warden configuration
  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :database_authenticatable
    manager.default_strategies(scope: :user).unshift :rememberable
  end
end
