import {
  CaseType,
  CaseStatus,
  DocumentType,
  User as DbUser,
  Case as DbCase,
  CaseDocument as DbCaseDocument,
  CaseDetail as DbCaseDetail,
  Team as DbTeam,
  TeamMember as DbTeamMember,
  Document as DbDocument,
} from '@/lib/db/schema';

// UI-friendly versions of database types

export interface User {
  id: string;
  email: string | null;
  firstName: string | null;
  lastName: string | null;
  role: string | null;
  profileImage: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Case {
  id: string;
  title: string;
  description: string | null;
  summary: string | null;
  referenceNumber: string;
  caseType: CaseType;
  status: CaseStatus;
  createdBy: string | null;
  active: boolean | null;
  createdAt: string;
  updatedAt: string;
}

export interface CaseDetail {
  id: string;
  caseId: string;
  plaintiffInfo: string | null;
  defendantInfo: string | null;
  legalIssues: string | null | string[];
  relevantLaws: string | null;
  timeline: string | null | TimelineEvent[];
  teachingNotes: string | null;
  assignmentDetails: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TimelineEvent {
  date: string;
  description: string;
}

export interface Document {
  id: string;
  title: string;
  documentType: DocumentType;
  content: string | null;
  fileUrl: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Team {
  id: string;
  caseId: string;
  name: string;
  role: string;
  createdAt: string;
  updatedAt: string;
}

export interface TeamMember {
  id: string;
  teamId: string;
  userId: string;
  createdAt: string;
  updatedAt: string;
}
