// Export enums
export * from './enums';

// Export tables
export * from './tables';

// Export relations
export * from './relations';

// Export types
export type User = typeof import('./tables').users.$inferSelect;
export type NewUser = typeof import('./tables').users.$inferInsert;

export type Case = typeof import('./tables').cases.$inferSelect;
export type NewCase = typeof import('./tables').cases.$inferInsert;

export type CaseDetail = typeof import('./tables').caseDetails.$inferSelect;
export type NewCaseDetail = typeof import('./tables').caseDetails.$inferInsert;

export type CaseDocument = typeof import('./tables').caseDocuments.$inferSelect;
export type NewCaseDocument = typeof import('./tables').caseDocuments.$inferInsert;

export type Team = typeof import('./tables').teams.$inferSelect;
export type NewTeam = typeof import('./tables').teams.$inferInsert;

export type TeamMember = typeof import('./tables').teamMembers.$inferSelect;
export type NewTeamMember = typeof import('./tables').teamMembers.$inferInsert;

export type Document = typeof import('./tables').documents.$inferSelect;
export type NewDocument = typeof import('./tables').documents.$inferInsert;

export type CaseEvent = typeof import('./tables').caseEvents.$inferSelect;
export type NewCaseEvent = typeof import('./tables').caseEvents.$inferInsert;

// Backward compatibility to make migration easier
// Re-export enums that components might be directly importing
export { UserRole, TeamRole, CaseStatus, CaseType, DocumentType } from './enums';
