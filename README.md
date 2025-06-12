# BizLaw - Legal Education Simulation Platform

[![Coverage Status](https://coveralls.io/repos/github/MattMencel/bizlaw/badge.svg)](https://coveralls.io/github/MattMencel/bizlaw)

A comprehensive Rails application designed for college business law courses, enabling students to work in teams on legal case simulations, particularly focused on sexual harassment lawsuit negotiations.

## 🏗️ Architecture

**Hybrid API/Web Application** built with Rails 8.0.2, supporting both JSON API endpoints (`/api/v1/`) and traditional Rails views with an API-first design approach.

### Technology Stack

- **Backend**: Rails 8.0.2, PostgreSQL with UUIDs, Solid Queue/Cache/Cable
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS, Importmap
- **Authentication**: Devise with JWT tokens, Google OAuth2, Pundit authorization
- **Testing**: RSpec + Cucumber + Capybara with Playwright driver

### Core Models

- `User` - Students, instructors, and administrators with role-based access
- `Team` - User groups with many-to-many relationships
- `Case` - Legal simulations with JSONB metadata for plaintiff/defendant info
- `Document` - File attachments with polymorphic associations
- `CaseEvent` - Audit trail for activity tracking
- `Course` - Educational courses with instructor management
- `License` - Multi-tenant licensing system

## 🚀 Getting Started

### Prerequisites

- Ruby 3.3.0+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- Redis (for caching and real-time features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/bizlaw.git
   cd bizlaw
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Database setup**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Start the development server**
   ```bash
   bin/dev                    # Start with Foreman (Rails + Tailwind watch)
   # OR
   bin/rails server          # Rails server only
   ```

## 🧪 Testing

### Test Suites

```bash
bin/rspec                  # Run RSpec unit/integration tests
bin/cucumber               # Run Cucumber BDD tests
bin/rails test:system     # Run system tests with Capybara + Playwright
```

### Code Quality

```bash
bin/rubocop                # Run linter with Omakase Ruby styling
bin/brakeman               # Security vulnerability scanner
```

## 📊 Database

### Key Patterns

- **UUID Primary Keys** for all major entities
- **Soft Deletion** via `SoftDeletable` concern
- **PostgreSQL Enums** for type-safe status fields
- **JSONB Columns** for flexible metadata storage

### Database Commands

```bash
bin/rails db:reset         # Drop, create, migrate, and seed
bin/rails db:migrate       # Run pending migrations
bin/rails db:seed          # Seed database
```

## 🔌 API Documentation

The application provides versioned REST APIs with JSON:API compliance:

- **Base URL**: `/api/v1/`
- **Authentication**: JWT tokens via Devise
- **Rate Limiting**: Rack::Attack protection
- **Pagination**: Kaminari for efficient data access

### API Endpoints

- `POST /api/v1/sessions` - Authentication
- `GET /api/v1/teams` - Team management
- `GET /api/v1/cases` - Case simulations
- `POST /api/v1/documents` - File uploads

## 🏫 Educational Features

### Case Simulations
- Sexual harassment lawsuit negotiations
- Team-based collaborative workflows
- Document management and sharing
- Real-time activity tracking

### Course Management
- Instructor-led course creation
- Student enrollment via invitations
- Multi-tenant organization support
- License-based access control

## 🚢 Deployment

The application is configured for deployment on Fly.io:

```bash
fly deploy                 # Deploy to production
```

### Environment Variables

Key configuration variables (see `config/credentials.yml.enc`):
- `DATABASE_URL`
- `REDIS_URL`
- `SECRET_KEY_BASE`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Run the test suite (`bin/rspec && bin/cucumber`)
4. Commit your changes (`git commit -am 'Add new feature'`)
5. Push to the branch (`git push origin feature/new-feature`)
6. Create a Pull Request

### Development Guidelines

- Follow Rails Omakase conventions
- Write tests for new features (RSpec + Cucumber)
- Use existing architectural patterns
- Ensure code passes Rubocop and Brakeman scans

## 📝 License

This project is licensed under [Your License] - see the LICENSE file for details.

## 📞 Support

For technical support or questions about the educational platform, please contact [your-support-email].
