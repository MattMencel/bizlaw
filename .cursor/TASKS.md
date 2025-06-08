# Legal Negotiation Simulation MVP Task List

Task list generated from [.prd/LEGAL_SIMULATION_PRD.md](../.prd/LEGAL_SIMULATION_PRD.md)

## Completed Tasks
- [x] Draft initial MVP Product Requirements Document (PRD)
- [x] Set up `.prd` directory and MVP PRD file

## User Roles & Authentication
- [ ] As a user, I can log in for the first time and have my account automatically created. _(2 pts)_
- [ ] As a user, I can see my assigned role (Plaintiff, Defendant, Admin, Instructor) after logging in. _(2 pts)_
- [ ] As an admin, I can assign the instructor role to a user. _(2 pts)_

## Case Setup
- [ ] As an admin or instructor, I can create a new case with a title and description. _(1 pt)_
- [ ] As an admin or instructor, I can upload evidence or briefing documents to a case. _(2 pts)_
- [ ] As an admin or instructor, I can assign a user to a team. _(2 pts)_
- [ ] As an admin or instructor, I can assign teams to a case. _(2 pts)_

## Negotiation Rounds
- [ ] As a team member, I can view the current case and its details. _(1 pt)_
- [ ] As a team, we can submit an offer or counteroffer for the current round. _(2 pts)_
- [ ] As the system, I can track and store all offers and rounds for a case. _(2 pts)_
- [ ] As a team, I receive feedback after submitting an offer ("too high/low"). _(2 pts)_

## Hidden Client Range
- [ ] As the system, I maintain a hidden acceptable range for each team and use it to generate feedback. _(2 pts)_

## Arbitration Trigger
- [ ] As the system, I trigger arbitration and determine a final settlement if no agreement is reached after N rounds. _(2 pts)_

## Basic Scoring
- [ ] As the system, I calculate and display a score for each team based on timeliness and closeness to the client's ideal. _(2 pts)_

## Dashboard
- [ ] As a user, I can view a dashboard showing the case timeline, negotiation history, and feedback. _(3 pts)_
- [ ] As an admin or instructor, I can monitor all teams' progress from the dashboard. _(2 pts)_

## Implementation Plan
- Work through the user stories above, one at a time, starting with authentication and case setup.
- Mark stories as complete as they are finished.
- Update this list as requirements or priorities change.

### Relevant Files
- .prd/LEGAL_SIMULATION_PRD.md - Product Requirements Document (source for this task list)
- .cursor/TASKS.md - This task list
- (Add new files here as they are created or modified)
