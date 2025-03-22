import type * as DbSchema from '@/lib/db/schema';

import type * as UiTypes from './db';

/**
 * Format a date value to ISO string
 * @param date Date object or string
 * @returns Formatted date string
 */
export function formatDate(date: Date | string): string {
  if (date instanceof Date) {
    return date.toISOString();
  }
  return String(date); // More robust than toString()
}

export function dbToUiCase(dbCase: DbSchema.Case): UiTypes.Case {
  return {
    ...dbCase,
    id: String(dbCase.id),
    createdAt: formatDate(dbCase.createdAt),
    updatedAt: formatDate(dbCase.updatedAt),
  };
}

export function dbToUiDocument(doc: DbSchema.CaseDocument): UiTypes.Document {
  return {
    id: String(doc.id),
    title: doc.title,
    documentType: doc.documentType,
    content: doc.content,
    fileUrl: doc.fileUrl,
    createdAt: formatDate(doc.createdAt),
    updatedAt: formatDate(doc.updatedAt),
  };
}

export function dbToUiCaseDetail(detail: DbSchema.CaseDetail): UiTypes.CaseDetail {
  return {
    ...detail,
    id: String(detail.id),
    caseId: String(detail.caseId),
    createdAt: formatDate(detail.createdAt),
    updatedAt: formatDate(detail.updatedAt),
  };
}
