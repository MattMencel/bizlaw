# Product Requirements Document (PRD): Legal Negotiation Simulation Web Application (MVP)

---

## 1. Overview

**Purpose:**
Deliver a minimum viable product (MVP) for a legal negotiation simulation web app for college courses, focusing on sexual harassment lawsuit negotiation. The MVP will allow students to participate in a basic negotiation, receive feedback, and complete a simulated case.

**Target Users:**
- Plaintiff Team (students)
- Defendant Team (students)
- Admin/Instructor

---

## 2. MVP Features & Requirements

### 2.1. User Roles & Authentication ✅ COMPLETED
- ✅ **Authentication System**: Devise with email/password + Google OAuth2
- ✅ **User Roles**: Multi-layered system with student/instructor/admin + org_admin
- ✅ **Team Roles**: Member/manager roles within teams
- ✅ **API Authentication**: JWT tokens for API access
- ✅ **Organization Management**: Multi-tenant with automatic domain-based assignment

### 2.2. Case Setup ✅ COMPLETED
- ✅ **Case Management**: Comprehensive case model with types, status workflow, difficulty levels
- ✅ **Course System**: Full course management with enrollment and academic terms
- ✅ **Document Upload**: Polymorphic document attachments with file validation
- ✅ **Team Assignment**: CaseTeam model for team-case relationships with roles
- ✅ **API Support**: REST API with JSON:API serialization

### 2.3. Negotiation Rounds 🔄 PARTIALLY IMPLEMENTED
- ✅ **Case Viewing**: Teams can view case details and metadata
- 🔄 **Offer Submission**: Case status workflow exists, needs negotiation UI
- 🔄 **Round Tracking**: CaseEvent model for audit trails, needs specific offer logic
- ❌ **Client Ranges**: Not implemented - needs hidden range system
- ❌ **Feedback System**: Not implemented - needs offer evaluation logic

### 2.4. Arbitration Trigger ❌ NOT IMPLEMENTED
- ❌ **Arbitration Logic**: Not implemented - needs automatic arbitration system
- ❌ **Settlement Calculation**: Not implemented - needs final settlement logic

### 2.5. Basic Scoring ❌ NOT IMPLEMENTED
- ❌ **Scoring System**: Not implemented - needs scoring algorithm
- ❌ **Performance Metrics**: Not implemented - needs timeliness and accuracy tracking

### 2.6. Dashboard ✅ COMPLETED
- ✅ **User Dashboard**: Navigation system with left sidebar and comprehensive views
- ✅ **Case Timeline**: Basic case viewing and status tracking
- ✅ **Admin Monitoring**: Admin controllers with organization and user management
- ✅ **Team Progress**: Course and team management with progress tracking

---

## 3. Implementation Plan (MVP)

### 3.1. Requirements & UI/UX Design
- Define user roles, simulation flow, and data models
- Create wireframes for dashboard and negotiation interface

### 3.2. Backend & API
- Endpoints for case management, negotiation rounds, arbitration, and scoring
- Simple logic for hidden client ranges and arbitration

### 3.3. Database Schema
- Tables: Users, Teams, Cases, NegotiationRounds, Offers, ClientParameters

### 3.4. Frontend
- Dashboard and negotiation interface

### 3.5. Testing & Deployment
- Unit and integration tests for core logic
- Deploy MVP to test environment

---

## 4. Success Criteria (MVP)

### ✅ COMPLETED CRITERIA
- ✅ **Student Login & Teams**: Students can log in via Google OAuth2 and join teams through course enrollment
- ✅ **Admin Case Setup**: Admins can create cases, manage courses, upload documents, and assign teams
- ✅ **Progress Monitoring**: Comprehensive admin dashboard with organization and user management

### 🔄 PARTIALLY COMPLETED CRITERIA
- 🔄 **Case Participation**: Students can view cases but negotiation interface needs completion
- 🔄 **System Stability**: Core platform is stable, negotiation features need implementation

### ❌ REMAINING CRITERIA
- ❌ **Negotiation Rounds**: Offer submission, feedback, and round progression not implemented
- ❌ **Arbitration System**: Automatic arbitration trigger and settlement calculation needed
- ❌ **Scoring System**: Performance scoring based on timeliness and accuracy needed

## 5. Implementation Status Summary

**Overall Progress: ~70% Complete**
- **Foundation (100%)**: Authentication, user management, organization system
- **Course Management (100%)**: Full course creation, enrollment, team management
- **Case Infrastructure (90%)**: Models and API complete, UI needs enhancement
- **Document System (100%)**: File upload, validation, and management complete
- **Negotiation Engine (20%)**: Core tracking exists, negotiation logic needed
- **Scoring & Analytics (0%)**: Not yet implemented
