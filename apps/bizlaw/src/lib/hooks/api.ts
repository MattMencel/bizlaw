'use client';

import { useState, useEffect, useCallback } from 'react';

import type { ListCasesParams, Case } from '../types/api';
import { api, ApiResponse, PaginatedApiResponse } from '../types/api';

// Generic hook for any API request
export function useApiRequest<TData, TParams = void>(
  apiCall: (params: TParams) => Promise<TData>,
  initialParams?: TParams,
  skipInitialFetch = false,
) {
  const [data, setData] = useState<TData | null>(null);
  const [isLoading, setIsLoading] = useState(!skipInitialFetch);
  const [error, setError] = useState<Error | null>(null);

  const execute = useCallback(
    async (params: TParams = initialParams as TParams) => {
      setIsLoading(true);
      setError(null);

      try {
        const result = await apiCall(params);
        setData(result);
        return result;
      }
      catch (err) {
        const error = err instanceof Error ? err : new Error(String(err));
        setError(error);
        throw error;
      }
      finally {
        setIsLoading(false);
      }
    },
    [apiCall, initialParams],
  );

  useEffect(() => {
    if (!skipInitialFetch && initialParams !== undefined) {
      execute(initialParams);
    }
  }, [execute, initialParams, skipInitialFetch]);

  return {
    data,
    isLoading,
    error,
    execute,
  };
}

// Hook for listing cases
export function useCases(initialParams?: Partial<ListCasesParams>, skipInitialFetch = false) {
  return useApiRequest(params => api.getCases(params), initialParams, skipInitialFetch);
}

// Hook for getting a single case
export function useCase(id: number | null, skipInitialFetch = false) {
  return useApiRequest(
    () => (id ? api.getCase(id) : Promise.reject(new Error('Case ID is required'))),
    undefined,
    skipInitialFetch || id === null,
  );
}

// Hook for creating a case
export function useCreateCase() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const createCase = async (data: Omit<Case, 'id' | 'createdAt' | 'updatedAt'>) => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await api.createCase(data);
      return result;
    }
    catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      throw error;
    }
    finally {
      setIsLoading(false);
    }
  };

  return {
    createCase,
    isLoading,
    error,
  };
}

// Hook for updating a case
export function useUpdateCase() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const updateCase = async (id: number, data: Partial<Omit<Case, 'id' | 'createdAt' | 'updatedAt'>>) => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await api.updateCase(id, data);
      return result;
    }
    catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      throw error;
    }
    finally {
      setIsLoading(false);
    }
  };

  return {
    updateCase,
    isLoading,
    error,
  };
}

// Hook for deleting a case
export function useDeleteCase() {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const deleteCase = async (id: number) => {
    setIsLoading(true);
    setError(null);

    try {
      const result = await api.deleteCase(id);
      return result;
    }
    catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      throw error;
    }
    finally {
      setIsLoading(false);
    }
  };

  return {
    deleteCase,
    isLoading,
    error,
  };
}
