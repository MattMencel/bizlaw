import type { Case } from '@/lib/db/schema';

export interface CaseResponse extends Case {
  teamCount?: number
  // Any other API-specific fields
}
