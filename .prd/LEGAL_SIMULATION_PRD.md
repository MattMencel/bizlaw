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

### 2.1. User Roles & Authentication
- Simple login (email/password or team code)
- Roles: Plaintiff team, Defendant team, Admin

### 2.2. Case Setup
- Admin can create a case with title, description, and upload evidence/briefing documents
- Teams are assigned to a case

### 2.3. Negotiation Rounds
- Teams submit offers/counteroffers each round
- System tracks rounds and offers
- Hidden client "acceptable range" for each team (simple logic)
- After each round, teams receive basic feedback ("too high/low")

### 2.4. Arbitration Trigger
- If no agreement after a set number of rounds, system triggers arbitration and determines a final settlement (simple logic)

### 2.5. Basic Scoring
- Score based on timeliness (number of rounds) and how close the settlement is to the client's ideal

### 2.6. Dashboard
- Teams see case timeline, negotiation history, and feedback
- Admin can monitor progress

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
- Students can log in, join a team, and participate in a negotiation
- Admin can set up a case and monitor progress
- Negotiation rounds, feedback, arbitration, and scoring work as described
- The app is stable and usable for a classroom simulation
