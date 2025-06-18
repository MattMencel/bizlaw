# Legal Negotiation Simulation MVP Task List

Task list generated from [.prd/LEGAL_SIMULATION_PRD.md](../.prd/LEGAL_SIMULATION_PRD.md)

## Completed Tasks
- [x] Draft initial MVP Product Requirements Document (PRD)
- [x] Set up `.prd` directory and MVP PRD file

## User Roles & Authentication
- [x] As a user, I can log in for the first time and have my account automatically created. _(2 pts)_ - Completed: Devise authentication with Google OAuth2 and automatic organization assignment
- [x] As a user, I can see my assigned role (Plaintiff, Defendant, Admin, Instructor) after logging in. _(2 pts)_ - Completed: Multi-layered role system with student/instructor/admin roles plus org_admin and team roles
- [x] As an admin, I can assign the instructor role to a user. _(2 pts)_ - Completed: Admin::UsersController with role management and org_admin assignment

## Case Setup
- [x] As an admin or instructor, I can create a new case with a title and description. _(1 pt)_ - Completed: Case model with comprehensive business logic, API endpoints, and course management system
- [x] As an admin or instructor, I can upload evidence or briefing documents to a case. _(2 pts)_ - Completed: Document model with polymorphic attachments to cases, file validation, and workflow management
- [x] As an admin or instructor, I can assign a user to a team. _(2 pts)_ - Completed: Team management with member roles, course enrollment, and invitation system
- [x] As an admin or instructor, I can assign teams to a case. _(2 pts)_ - Completed: CaseTeam model for team-case assignments with role specifications

## Negotiation Rounds
- [x] As a team member, I can view the current case and its details. _(1 pt)_ - Completed: Case model with metadata storage, API endpoints, and basic web views
- [x] As a team, we can submit an offer or counteroffer for the current round. _(2 pts)_ - Completed: Full offer submission portal with counter-proposal system, client consultation, and argument templates
- [x] As the system, I can track and store all offers and rounds for a case. _(2 pts)_ - Completed: NegotiationRound and SettlementOffer models with comprehensive tracking
- [x] As a team, I receive feedback after submitting an offer ("too high/low"). _(2 pts)_ - Completed: Real-time client feedback system with mood indicators and strategic guidance

## Hidden Client Range
- [ ] As the system, I maintain a hidden acceptable range for each team and use it to generate feedback. _(2 pts)_

## Arbitration Trigger
- [ ] As the system, I trigger arbitration and determine a final settlement if no agreement is reached after N rounds. _(2 pts)_

## Basic Scoring
- [ ] As the system, I calculate and display a score for each team based on timeliness and closeness to the client's ideal. _(2 pts)_

## Dashboard
- [x] As a user, I can view a dashboard showing the case timeline, negotiation history, and feedback. _(3 pts)_ - Completed: Navigation system with left sidebar, courses/teams/cases views, and comprehensive user dashboard
- [x] As an admin or instructor, I can monitor all teams' progress from the dashboard. _(2 pts)_ - Completed: Admin controllers, organization management, and instructor oversight capabilities

## Implementation Plan
- Work through the user stories above, one at a time, starting with authentication and case setup.
- Mark stories as complete as they are finished.
- Update this list as requirements or priorities change.

---

## Sexual Harassment Lawsuit Settlement Simulation

### First Simulation Implementation
- [ ] **Complete Sexual Harassment Simulation** _(118 pts total)_ - Detailed breakdown in SEXUAL_HARASSMENT_SIMULATION_TASKS.md
  - Phase 1: Core Infrastructure (database models, business logic, APIs)
  - Phase 2: Advanced simulation features (dynamic ranges, content management)
  - Phase 3: User experience (dashboards, negotiation interface, educational tools)
  - Phase 4: Assessment and administration (scoring, instructor tools, security)

### Implementation References
- [Detailed Implementation Tasks](.cursor/SEXUAL_HARASSMENT_SIMULATION_TASKS.md) - Complete task breakdown with 126 story points (70 completed)
- [BDD Feature Stories](../features/offer_submission_portal.feature) - Cucumber scenarios for offer submission portal
- [Simulation PRD](../.prd/SCENARIO_SEXUAL_HARASSMENT_SIMULATION_PRD.md) - Complete product requirements document

### Recently Completed: Navigation & Interface Improvements ✅
- **Navigation System**: Fully hierarchical navigation with context switcher
- **Routes**: Comprehensive routing system with `/cases/:id/negotiations`, `/cases/:id/evidence_vault`, API endpoints
- **Controllers**: Complete suite including `NegotiationsController`, `EvidenceVaultController`, API controllers
- **Views**: 12+ comprehensive views across evidence vault, negotiations, and dashboard interfaces
- **Features**: Evidence vault with search/annotation, offer submission with templates, real-time feedback, mobile responsive
- **Integration**: Full API integration with simulation models and business logic
- **Testing**: Comprehensive Cucumber BDD feature coverage

### Key Milestones - UPDATED STATUS (June 18, 2025)
- [x] **Phase 1 Complete**: Core simulation infrastructure ready _(Weeks 1-2)_ ✅
- [x] **Phase 2 Complete**: Dynamic simulation logic implemented _(Weeks 3-4)_ ✅
- [x] **Phase 3 Complete**: Student-facing interfaces complete _(Weeks 5-6)_ ✅
  - ✅ Evidence Vault Interface (Full search, annotation, document management)
  - ✅ Offer Submission Portal (Templates, counter-offers, client consultation)
  - ✅ Navigation System (Hierarchical sidebar with context switching)
  - ✅ Dashboard Integration (Student/instructor/admin dashboards)
  - 🔄 Strategy Planning Board (ON HOLD - not critical for launch)
- [x] **Phase 4 Complete**: Assessment and admin tools _(Weeks 7-8)_ ✅
  - ✅ Real-time scoring dashboard with comprehensive analytics
  - ✅ Instructor monitoring dashboard with intervention tools
  - ✅ Grading and feedback tools with manual adjustment capabilities
  - ✅ Post-simulation analysis tools with PDF export
  - ✅ AI Phase 1: Google AI Integration Setup (GoogleAiService, testing, fallbacks)
  - 🔄 Minor remaining: scenario preview system, content handling
- [ ] **AI Phase 2**: Client feedback integration _(Week 9)_
- [ ] **Pilot Testing**: Instructor and student validation _(Week 10)_
- [ ] **Production Launch**: First live simulation deployment _(Week 11)_

---

### Relevant Files
- .prd/LEGAL_SIMULATION_PRD.md - MVP Product Requirements Document
- .prd/SCENARIO_SEXUAL_HARASSMENT_SIMULATION_PRD.md - Sexual harassment simulation detailed requirements
- .cursor/TASKS.md - This main task list
- .cursor/SEXUAL_HARASSMENT_SIMULATION_TASKS.md - Detailed simulation implementation tasks
- features/sexual_harassment_simulation.feature - BDD acceptance criteria
