# frozen_string_literal: true

ruby file: ".ruby-version"

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# API-specific gems
gem "kaminari", "~> 1.2" # Pagination
gem "jsonapi-serializer", "~> 2.2" # Fast JSON:API serialization
gem "rack-attack", "~> 6.7" # Rate limiting

# Metrics and monitoring
gem "statsd-instrument", "~> 3.5" # StatsD client for metrics
gem "dogstatsd-ruby", "~> 5.6" # Enhanced StatsD client with tagging support

# AI Integration
gem "gemini-ai", "~> 4.2" # Google Gemini AI client

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# QR Code generation for invitations
gem "rqrcode", "~> 3.1"
gem "chunky_png", "~> 1.4"

# PDF generation
gem "prawn", "~> 2.4"
gem "prawn-table", "~> 0.2"

# Authentication & Authorization
gem "devise", "~> 4.9"
gem "devise-jwt", "~> 0.12"
gem "pundit", "~> 2.3"
gem "omniauth", "~> 2.1"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  gem "dotenv-rails", "~> 3.1"
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  eval_gemfile "gemfiles/rubocop.gemfile"

  # RSpec for Rails testing

  gem "rspec-rails", "~> 8.0.1"

  # Factory Bot for test data generation
  gem "factory_bot_rails"

  # Faker for generating test data
  gem "faker"

  # Cucumber for BDD
  gem "cucumber-rails", "~> 3.1", require: false
  gem "cucumber", "~> 9.2.1"

  # Rswag for API documentation
  gem "rswag-specs", "~> 2.13"

  # Accessibility testing
  gem "axe-core-rspec", "~> 4.10"

  # Rails controller testing helpers
  gem "rails-controller-testing"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # N+1 query detection
  gem "bullet"

  # Ruby language server for IDE features
  gem "solargraph"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Shoulda Matchers for RSpec
  gem "shoulda-matchers"

  # Pundit matchers for policy testing
  gem "pundit-matchers"

  # Database Cleaner for test database management
  gem "database_cleaner-active_record"

  # Capybara Playwright Driver
  gem "capybara-playwright-driver"

  gem "email_spec"
  gem "timecop"

  # Code coverage analysis
  gem "simplecov", require: false
end

gem "dockerfile-rails", ">= 1.7", group: :development
gem "rswag-api", "~> 2.13"
gem "rswag-ui", "~> 2.13"
gem "active_storage_validations"
