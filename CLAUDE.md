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
bundle exec rspec                  # Run RSpec unit/integration tests
bundle exec cucumber               # Run Cucumber BDD tests
bundle exec rails test:system     # Run system tests with Capybara + Playwright
bundle exec rspec spec/system/    # Run accessibility & system tests
bundle exec rspec spec/e2e/       # Run end-to-end tests with Playwright
bundle exec rspec --tag accessibility  # Run only accessibility tests
```

**Code Quality:**
```bash
bin/rubocop                # Run linter with Omakase Ruby styling
bin/brakeman               # Security vulnerability scanner
```

**Git and Pre-commit:**
```bash
git rebase main            # Rebase current branch from trunk before pushing, and ask for help on merge conflicts
git commit -m "message"    # NEVER skip pre-commit hooks with --no-verify
git push origin branch     # Push changes after successful commit
```
**IMPORTANT**: Always allow pre-commit hooks to run. If pre-commit checks fail, fix the issues before committing. Never use `--no-verify` or `--skip-ci` flags to bypass these checks. If you cannot resolve pre-commit issues, stop and ask for review.

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
- `Simulation` (multiple simulations per case) supporting concurrent team negotiations
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
- **Accessibility Tests**: axe-core-rspec for WCAG 2.0/2.1 AA compliance
- **Performance**: Custom `QueryCounter` for N+1 detection

### Rails Conventions

This codebase follows Rails Omakase conventions:
- RESTful routing patterns
- Concerns for shared behavior (`HasUuid`, `HasTimestamps`, `SoftDeletable`)
- Service objects for complex business logic
- Strong parameters and security best practices
- ActiveRecord validations and associations

When working with this codebase, leverage the existing patterns rather than creating new architectural approaches.

### Responsive Design Guidelines

**Always follow responsive design best practices:**

- **Mobile-First Approach**: Design for mobile devices first, then progressively enhance for larger screens
- **Breakpoint Strategy**: Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`) consistently
- **Layout Considerations**:
  - Sidebar: `w-80` (320px) fixed width with `lg:block hidden` for responsive behavior
  - Main content: `lg:ml-80` (320px left margin) to account for sidebar on desktop
  - Avoid `mx-auto` centering when using fixed sidebars - use left-aligned content with appropriate padding
- **Content Spacing**: Use responsive padding/margins that work across breakpoints
- **Touch Targets**: Ensure interactive elements are minimum 44px for mobile accessibility
- **Typography**: Use responsive text sizes (`text-sm sm:text-base lg:text-lg`) for optimal readability
- **Grid Systems**: Leverage Tailwind's responsive grid classes for consistent layouts
- **Image Optimization**: Use responsive images with appropriate `srcset` attributes
- **Testing**: Always test layouts on multiple screen sizes and devices

## MCP Integration

This project supports Model Context Protocol (MCP) integrations for enhanced development workflows:

### GitHub MCP
For GitHub operations, use the GitHub MCP tools instead of bash commands:
- Repository management (create, fork, branches)
- Issues and pull requests (create, update, review, merge)
- Code and security scanning alerts
- Notifications and project management
- File operations (create, update, delete files directly in GitHub)

### Playwright MCP
For browser automation and E2E testing:
- Web page navigation and interaction
- Screenshot and snapshot capture
- Form filling and element interaction
- Test generation and execution
- Accessibility testing with browser tools

These MCPs provide more reliable and feature-rich alternatives to traditional CLI tools for GitHub and browser automation tasks.

## Pull Request Review Guidelines

When reviewing pull requests, follow this systematic approach:

### Review Process
1. **Checkout and Setup**
   ```bash
   git checkout main && git pull origin main
   git checkout <pr-branch>
   bundle install  # If dependencies changed
   ```

2. **Analysis Phase**
   - Use GitHub MCP tools to fetch PR details and changed files
   - Review PR description, type (feature/bugfix/dependency), and scope
   - Identify the primary changes and potential impact areas

3. **Testing Phase**
   - Run relevant test suites based on changed files:
     - `bundle exec rspec spec/models/` for model changes
     - `bundle exec rspec spec/requests/` for API changes
     - `bundle exec rspec spec/system/` for UI changes
     - `bundle exec cucumber` for feature changes
   - For dependency updates: verify bundle install success and run core test suites
   - Check that existing test failures are pre-existing, not introduced by the PR

4. **Code Quality Checks**
   ```bash
   bin/rubocop     # Style and code quality
   bin/brakeman    # Security analysis
   ```

### Review Criteria

**✅ APPROVE when:**
- All relevant tests pass or failures are pre-existing
- Code follows Rails Omakase conventions and project patterns
- Security best practices are maintained
- Dependencies are safe minor/patch updates
- Documentation is updated if needed

**🔄 REQUEST CHANGES when:**
- New test failures introduced by the PR
- Security vulnerabilities or bad practices
- Breaking changes without proper migration strategy
- Code doesn't follow project conventions
- Missing tests for new functionality

**📝 COMMENT for:**
- Suggestions for improvement
- Questions about implementation approach
- Non-blocking style or performance recommendations

### Special Cases

**Dependency Updates (like Dependabot PRs):**
- Focus on version compatibility and security
- Check for breaking changes in release notes
- Verify bundle install succeeds
- Run core test suite to ensure no regressions
- Generally safe to approve minor/patch updates from trusted sources

**Feature PRs:**
- Ensure comprehensive test coverage
- Check for proper error handling
- Verify UI/UX follows design patterns
- Test accessibility compliance if UI changes

**Bugfix PRs:**
- Verify the fix addresses the root cause
- Check for regression test coverage
- Ensure fix doesn't introduce new issues

## Project Documentation

- **PRDs**: Product Requirements Documents are located in the `.prd/` folder
- **Tasks**: Task lists and project planning are located in the `.cursor/` folder
