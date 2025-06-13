# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

**Development Server:**
```bash
bin/dev                    # Start development server with Foreman (Rails + Tailwind watch)
bin/rails server          # Start Rails server only
```

**Testing:**
```bash
bin/rspec                  # Run RSpec unit/integration tests
bin/cucumber               # Run Cucumber BDD tests
bin/rails test:system     # Run system tests with Capybara + Playwright
```

**Code Quality:**
```bash
bin/rubocop                # Run linter with Omakase Ruby styling
bin/brakeman               # Security vulnerability scanner
```

**Database:**
```bash
bin/rails db:create        # Create databases
bin/rails db:migrate       # Run pending migrations
bin/rails db:seed          # Seed database
bin/rails db:reset         # Drop, create, migrate, and seed
```

## Architecture Overview

This is a **Legal Education Simulation Platform** built with Rails 8.0.2 for college business law courses. Students work in teams on legal case simulations (particularly sexual harassment lawsuit negotiations).

### Core Architecture Patterns

- **Hybrid API/Web Application**: Supports both JSON API endpoints (`/api/v1/`) and traditional Rails views
- **API-First Design**: Versioned REST APIs with JSON:API serialization
- **Service Layer**: Business logic in service objects (`MetricsService`, `RedisService`)
- **Domain-Driven Models**: Rich domain objects with clear business relationships

### Key Technology Stack

- **Backend**: Rails 8.0.2, PostgreSQL with UUIDs, modern Rails features (Solid Queue/Cache/Cable)
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, Importmap
- **Authentication**: Devise with JWT tokens, Google OAuth2, Pundit authorization
- **Testing**: RSpec + Cucumber + Capybara with Playwright driver

### Data Architecture

**Core Models:**
- `User` (students/instructors/admins) with role-based access
- `Team` (user groups) with many-to-many relationships
- `Case` (legal simulations) with JSONB metadata for `plaintiff_info`/`defendant_info`
- `Document` (file attachments) with polymorphic associations
- `CaseEvent` (audit trail) for activity tracking

**Key Patterns:**
- UUID primary keys for all major entities
- Soft deletion implemented via `SoftDeletable` concern
- PostgreSQL enums for type-safe status fields
- JSONB columns for flexible metadata storage

### API Design

- **Versioned APIs**: URL path (`/api/v1/`) and Accept header versioning
- **JSON:API Compliance**: Using `jsonapi-serializer` gem
- **Rate Limiting**: Rack::Attack for API protection
- **Pagination**: Kaminari for efficient data access

### Testing Strategy

- **Unit Tests**: RSpec with Factory Bot and comprehensive model coverage
- **BDD Tests**: Cucumber for user story validation
- **API Tests**: Request specs for all endpoints
- **System Tests**: Full E2E with Capybara + Playwright
- **Performance**: Custom `QueryCounter` for N+1 detection

### Rails Conventions

This codebase follows Rails Omakase conventions:
- RESTful routing patterns
- Concerns for shared behavior (`HasUuid`, `HasTimestamps`, `SoftDeletable`)
- Service objects for complex business logic
- Strong parameters and security best practices
- ActiveRecord validations and associations

When working with this codebase, leverage the existing patterns rather than creating new architectural approaches.

## Project Documentation

- **PRDs**: Product Requirements Documents are located in the `.prd/` folder
- **Tasks**: Task lists and project planning are located in the `.cursor/` folder
