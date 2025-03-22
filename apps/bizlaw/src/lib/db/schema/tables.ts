import { pgTable, uuid, text, timestamp, serial, integer, boolean } from 'drizzle-orm/pg-core';

import { UserRole, TeamRole, CaseStatus, CaseType, DocumentType } from './enums';

// Users table definition
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  firstName: text('first_name'),
  lastName: text('last_name'),
  role: text('role').$type<UserRole>().notNull().default(UserRole.STUDENT),
  profileImage: text('profile_image'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Cases table definition
export const cases = pgTable('cases', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description'),
  summary: text('summary'),
  referenceNumber: text('reference_number').notNull(),
  caseType: text('case_type').$type<CaseType>().notNull(),
  status: text('status').$type<CaseStatus>().notNull().default(CaseStatus.DRAFT),
  createdBy: uuid('created_by'),
  active: boolean('active').default(true),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Case details table
export const caseDetails = pgTable('case_details', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').notNull(),
  plaintiffInfo: text('plaintiff_info'),
  defendantInfo: text('defendant_info'),
  legalIssues: text('legal_issues'),
  relevantLaws: text('relevant_laws'),
  timeline: text('timeline'),
  teachingNotes: text('teaching_notes'),
  assignmentDetails: text('assignment_details'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Case documents table
export const caseDocuments = pgTable('case_documents', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').notNull(),
  title: text('title').notNull(),
  documentType: text('document_type').$type<DocumentType>().notNull(),
  content: text('content'),
  fileUrl: text('file_url'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Teams table
export const teams = pgTable('teams', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').notNull(),
  name: text('name').notNull(),
  role: text('role').$type<TeamRole>().notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Team members table
export const teamMembers = pgTable('team_members', {
  id: serial('id').primaryKey(),
  teamId: integer('team_id').notNull(),
  userId: uuid('user_id').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Documents table
export const documents = pgTable('documents', {
  id: serial('id').primaryKey(),
  teamId: integer('team_id').notNull(),
  title: text('title').notNull(),
  content: text('content'),
  fileUrl: text('file_url'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Case events table
export const caseEvents = pgTable('case_events', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').notNull(),
  title: text('title').notNull(),
  description: text('description'),
  eventDate: timestamp('event_date').notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});
