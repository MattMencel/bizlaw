import { relations } from 'drizzle-orm';
import { users, cases, caseDetails, caseDocuments, teams, teamMembers, documents, caseEvents } from './tables';

// Users relations
export const usersRelations = relations(users, ({ many }) => ({
  teamMembers: many(teamMembers),
}));

// Cases relations
export const casesRelations = relations(cases, ({ one, many }) => ({
  createdByUser: one(users, {
    fields: [cases.createdBy],
    references: [users.id],
  }),
  details: one(caseDetails, {
    fields: [cases.id],
    references: [caseDetails.caseId],
  }),
  documents: many(caseDocuments),
  teams: many(teams),
  events: many(caseEvents),
}));

// Case details relations
export const caseDetailsRelations = relations(caseDetails, ({ one }) => ({
  case: one(cases, {
    fields: [caseDetails.caseId],
    references: [cases.id],
  }),
}));

// Case documents relations
export const caseDocumentsRelations = relations(caseDocuments, ({ one }) => ({
  case: one(cases, {
    fields: [caseDocuments.caseId],
    references: [cases.id],
  }),
}));

// Teams relations
export const teamsRelations = relations(teams, ({ one, many }) => ({
  case: one(cases, {
    fields: [teams.caseId],
    references: [cases.id],
  }),
  members: many(teamMembers),
  documents: many(documents),
}));

// Team members relations
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

// Documents relations
export const documentsRelations = relations(documents, ({ one }) => ({
  team: one(teams, {
    fields: [documents.teamId],
    references: [teams.id],
  }),
}));

// Case events relations
export const caseEventsRelations = relations(caseEvents, ({ one }) => ({
  case: one(cases, {
    fields: [caseEvents.caseId],
    references: [cases.id],
  }),
}));
