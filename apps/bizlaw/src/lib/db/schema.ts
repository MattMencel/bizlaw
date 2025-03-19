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

// Courses table
export const courses = pgTable('courses', {
  id: serial('id').primaryKey(),
  name: text('name').notNull(),
  description: text('description'),
  professorId: uuid('professor_id').references(() => users.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Cases table
export const cases = pgTable('cases', {
  id: serial('id').primaryKey(),
  courseId: integer('course_id').references(() => courses.id),
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

// Enrollments table
export const enrollments = pgTable('enrollments', {
  id: serial('id').primaryKey(),
  userId: uuid('user_id').references(() => users.id),
  courseId: integer('course_id').references(() => courses.id),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Invitations table
export const invitations = pgTable('invitations', {
  id: uuid('id').defaultRandom().primaryKey(),
  email: text('email').notNull(),
  inviterId: uuid('inviter_id').references(() => users.id),
  courseId: integer('course_id').references(() => courses.id),
  role: text('role').notNull().default('student'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  expiresAt: timestamp('expires_at'),
});

// Define relations
export const usersRelations = relations(users, ({ many }) => ({
  courses: many(courses, { relationName: 'professorCourses' }),
  enrollments: many(enrollments),
  teamMembers: many(teamMembers),
  sentInvitations: many(invitations, { relationName: 'sentInvitations' }),
}));

export const coursesRelations = relations(courses, ({ many, one }) => ({
  professor: one(users, {
    fields: [courses.professorId],
    references: [users.id],
    relationName: 'professorCourses',
  }),
  cases: many(cases),
  enrollments: many(enrollments),
}));

export const casesRelations = relations(cases, ({ many, one }) => ({
  course: one(courses, {
    fields: [cases.courseId],
    references: [courses.id],
  }),
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

// Export type interfaces for each table

// User types
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

// Course types
export type Course = typeof courses.$inferSelect;
export type NewCourse = typeof courses.$inferInsert;

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

// Enrollment types
export type Enrollment = typeof enrollments.$inferSelect;
export type NewEnrollment = typeof enrollments.$inferInsert;

// Invitation types
export type Invitation = typeof invitations.$inferSelect;
export type NewInvitation = typeof invitations.$inferInsert;

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
  coursesTeaching?: Course[]
  enrollments?: Enrollment[]
  teamMembers?: TeamMember[]
  sentInvitations?: Invitation[]
}

export interface CourseWithRelations extends Course {
  professor?: User
  cases?: Case[]
  enrollments?: Enrollment[]
}

export interface CaseWithRelations extends Case {
  course?: Course
  teams?: Team[]
  events?: CaseEvent[]
}

export interface TeamWithRelations extends Team {
  case?: Case
  members?: TeamMember[]
  documents?: Document[]
}
