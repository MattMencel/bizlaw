// Re-export all types
export * from './db';
export * from './api';
export * from './utils';

// Any additional types that don't fit into the other files
export interface Pagination {
  page: number;
  pageSize: number;
  totalPages: number;
  totalItems: number;
}

export interface ApiResponse<T> {
  data: T;
  error?: string;
  pagination?: Pagination;
}
