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
- [ ] As a team, we can submit an offer or counteroffer for the current round. _(2 pts)_ - Partially implemented: Case model supports status workflow, needs negotiation round UI
- [ ] As the system, I can track and store all offers and rounds for a case. _(2 pts)_ - Partially implemented: CaseEvent model for audit trails, needs specific offer tracking
- [ ] As a team, I receive feedback after submitting an offer ("too high/low"). _(2 pts)_ - Not implemented: Needs negotiation logic and feedback system

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
- [Detailed Implementation Tasks](.cursor/SEXUAL_HARASSMENT_SIMULATION_TASKS.md) - Complete task breakdown with 118 story points
- [BDD Feature Stories](../features/sexual_harassment_simulation.feature) - Cucumber scenarios for acceptance testing
- [Simulation PRD](../.prd/SCENARIO_SEXUAL_HARASSMENT_SIMULATION_PRD.md) - Complete product requirements document

### Key Milestones
- [ ] **Phase 1 Complete**: Core simulation infrastructure ready _(Weeks 1-2)_
- [ ] **Phase 2 Complete**: Dynamic simulation logic implemented _(Weeks 3-4)_
- [ ] **Phase 3 Complete**: Student-facing interface complete _(Weeks 5-6)_
- [ ] **Phase 4 Complete**: Assessment and admin tools ready _(Weeks 7-8)_
- [ ] **Pilot Testing**: Instructor and student validation _(Week 9)_
- [ ] **Production Launch**: First live simulation deployment _(Week 10)_

---

### Relevant Files
- .prd/LEGAL_SIMULATION_PRD.md - MVP Product Requirements Document
- .prd/SCENARIO_SEXUAL_HARASSMENT_SIMULATION_PRD.md - Sexual harassment simulation detailed requirements
- .cursor/TASKS.md - This main task list
- .cursor/SEXUAL_HARASSMENT_SIMULATION_TASKS.md - Detailed simulation implementation tasks
- features/sexual_harassment_simulation.feature - BDD acceptance criteria
