import type { Case, Team, User, CaseEvent, Document, TeamMember, CaseDetail, CaseDocument } from '../schema';

/**
 * Combined types with relations for the entire schema
 */

export interface CaseWithRelations extends Case {
  teams?: Team[];
  events?: CaseEvent[];
  details?: CaseDetail;
  documents?: CaseDocument[];
  createdByUser?: User;
}

export interface TeamWithRelations extends Team {
  members?: TeamMemberWithRelations[];
  documents?: Document[];
  case?: Case;
}

export interface TeamMemberWithRelations extends TeamMember {
  team?: Team;
  user?: User;
}

export interface DocumentWithRelations extends Document {
  team?: Team;
}

export interface CaseDocumentWithRelations extends CaseDocument {
  case?: Case;
}

export interface CaseEventWithRelations extends CaseEvent {
  case?: Case;
}

export interface CaseDetailWithRelations extends CaseDetail {
  case?: Case;
}
