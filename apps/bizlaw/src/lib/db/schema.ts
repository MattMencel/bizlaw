import { relations } from 'drizzle-orm';
import { pgTable, text, timestamp, uuid, integer, boolean, serial } from 'drizzle-orm/pg-core';

// Users table
export const users = pgTable('users', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull().unique(),
  firstName: text('first_name'),
  lastName: text('last_name'),
  role: text('role').notNull().default('student'),
  profileImage: text('profile_image'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Cases table (modified to remove courseId reference)
export const cases = pgTable('cases', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description'),
  active: boolean('active').default(true),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Teams table
export const teams = pgTable('teams', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').references(() => cases.id),
  name: text('name').notNull(),
  role: text('role').notNull(), // 'plaintiff', 'defendant', 'judge'
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Team members table
export const teamMembers = pgTable('team_members', {
  id: serial('id').primaryKey(),
  teamId: integer('team_id').references(() => teams.id),
  userId: uuid('user_id').references(() => users.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Case events table
export const caseEvents = pgTable('case_events', {
  id: serial('id').primaryKey(),
  caseId: integer('case_id').references(() => cases.id),
  title: text('title').notNull(),
  description: text('description'),
  dueDate: timestamp('due_date'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Documents table
export const documents = pgTable('documents', {
  id: serial('id').primaryKey(),
  teamId: integer('team_id').references(() => teams.id),
  title: text('title').notNull(),
  content: text('content'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Define relations
export const usersRelations = relations(users, ({ many }) => ({
  teamMembers: many(teamMembers),
}));

export const casesRelations = relations(cases, ({ many }) => ({
  teams: many(teams),
  events: many(caseEvents),
}));

export const teamsRelations = relations(teams, ({ many, one }) => ({
  case: one(cases, {
    fields: [teams.caseId],
    references: [cases.id],
  }),
  members: many(teamMembers),
  documents: many(documents),
}));

export const teamMembersRelations = relations(teamMembers, ({ one }) => ({
  team: one(teams, {
    fields: [teamMembers.teamId],
    references: [teams.id],
  }),
  user: one(users, {
    fields: [teamMembers.userId],
    references: [users.id],
  }),
}));

export const caseEventsRelations = relations(caseEvents, ({ one }) => ({
  case: one(cases, {
    fields: [caseEvents.caseId],
    references: [cases.id],
  }),
}));

export const documentsRelations = relations(documents, ({ one }) => ({
  team: one(teams, {
    fields: [documents.teamId],
    references: [teams.id],
  }),
}));

// Export type interfaces for each table

// User types
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

// Case types
export type Case = typeof cases.$inferSelect;
export type NewCase = typeof cases.$inferInsert;

// Team types
export type Team = typeof teams.$inferSelect;
export type NewTeam = typeof teams.$inferInsert;

// Team member types
export type TeamMember = typeof teamMembers.$inferSelect;
export type NewTeamMember = typeof teamMembers.$inferInsert;

// Case event types
export type CaseEvent = typeof caseEvents.$inferSelect;
export type NewCaseEvent = typeof caseEvents.$inferInsert;

// Document types
export type Document = typeof documents.$inferSelect;
export type NewDocument = typeof documents.$inferInsert;

// Enum types for better type safety
export enum UserRole {
  ADMIN = 'admin',
  PROFESSOR = 'professor',
  STUDENT = 'student',
}

export enum TeamRole {
  PLAINTIFF = 'plaintiff',
  DEFENDANT = 'defendant',
  JUDGE = 'judge',
}

// Interface with relations for complete objects
export interface UserWithRelations extends User {
  teamMembers?: TeamMember[]
}

export interface CaseWithRelations extends Case {
  teams?: Team[]
  events?: CaseEvent[]
}

export interface TeamWithRelations extends Team {
  case?: Case
  members?: TeamMember[]
  documents?: Document[]
}

export interface TeamMemberWithRelations extends TeamMember {
  team?: Team
  user?: User
}

export interface DocumentWithRelations extends Document {
  team?: Team
}

export interface CaseEventWithRelations extends CaseEvent {
  case?: Case
}
