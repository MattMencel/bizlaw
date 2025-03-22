/**
 * Common enums across the schema
 */

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

export enum CaseStatus {
  DRAFT = 'draft',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

export enum CaseType {
  SEXUAL_HARASSMENT = 'sexual_harassment',
  DISCRIMINATION = 'discrimination',
  WRONGFUL_TERMINATION = 'wrongful_termination',
  CONTRACT_DISPUTE = 'contract_dispute',
  INTELLECTUAL_PROPERTY = 'intellectual_property',
}

export enum DocumentType {
  BRIEF = 'brief',
  EVIDENCE = 'evidence',
  RULING = 'ruling',
  OTHER = 'other',
}
