import type { Case } from './db'; // Update to reference UI types instead of DB types

export interface CaseResponse extends Case {
  teamCount?: number;
  details?: any;
  documents?: any[];
  // Any other API-specific fields
}
