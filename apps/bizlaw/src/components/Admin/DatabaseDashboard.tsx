'use client';

import { RefreshCw, Check, X, ChevronDown, ChevronUp, PlayCircle, AlertTriangle } from 'lucide-react';
import { useState, useEffect } from 'react';

// Helper function to safely get error messages
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

export default function DatabaseDashboard() {
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [runningMigration, setRunningMigration] = useState(false);
  const [expandedSection, setExpandedSection] = useState<string | null>('pending');

  const fetchStatus = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch('/api/admin/run-migrations');
      if (!response.ok) {
        throw new Error(`Failed to fetch migration status: ${response.statusText}`);
      }
      const data = await response.json();
      setStatus(data);
    }
    catch (err: unknown) {
      setError(getErrorMessage(err));
      console.error(err);
    }
    finally {
      setLoading(false);
    }
  };

  const runMigrations = async () => {
    setRunningMigration(true);
    setError(null);
    try {
      const response = await fetch('/api/admin/run-migrations', {
        method: 'POST',
      });
      if (!response.ok) {
        throw new Error(`Failed to run migrations: ${response.statusText}`);
      }
      const data = await response.json();
      setStatus(data);
      alert('Migrations completed successfully!');
    }
    catch (err: unknown) {
      setError(getErrorMessage(err));
      console.error(err);
    }
    finally {
      setRunningMigration(false);
    }
  };

  const toggleSection = (section: string) => {
    if (expandedSection === section) {
      setExpandedSection(null);
    }
    else {
      setExpandedSection(section);
    }
  };

  useEffect(() => {
    fetchStatus();
  }, []);

  if (loading && !status) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-lg p-6 max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Database Maintenance</h1>
        <button
          onClick={fetchStatus}
          className="flex items-center px-3 py-2 bg-gray-100 hover:bg-gray-200 rounded text-sm"
          disabled={loading}
        >
          <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border-l-4 border-red-500 p-4 text-red-700">
          <div className="flex items-center">
            <AlertTriangle className="h-5 w-5 mr-2" />
            <p className="font-medium">Error</p>
          </div>
          <p className="mt-1">{error}</p>
        </div>
      )}

      {status && (
        <>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-sm text-gray-500 uppercase tracking-wide mb-2">Database</h3>
              <p className="font-semibold text-lg">{status.migrations?.database?.database_name || 'Unknown'}</p>
              <p className="text-xs text-gray-500 mt-1 truncate">
                {status.migrations?.database?.postgres_version || 'Unknown version'}
              </p>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-sm text-gray-500 uppercase tracking-wide mb-2">Tables</h3>
              <p className="font-semibold text-lg">
                {status.migrations?.tables?.count || 0}
                {' '}
                tables
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Migration tracking:
                {' '}
                {status.migrations?.tables?.migrationTableExists
                  ? (
                    <span className="text-green-600 font-medium">Active</span>
                  )
                  : (
                    <span className="text-red-600 font-medium">Not set up</span>
                  )}
              </p>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-sm text-gray-500 uppercase tracking-wide mb-2">Migrations</h3>
              <p className="font-semibold text-lg">
                {status.migrations?.migrations?.applied || 0}
                {' '}
                /
                {status.migrations?.migrations?.total || 0}
                {' '}
                applied
              </p>
              <p className="text-xs text-gray-500 mt-1">
                {status.migrations?.migrations?.pending || 0}
                {' '}
                pending migrations
              </p>
            </div>
          </div>

          <div className="mb-6">
            <div className="border-b pb-2 mb-4">
              <button
                onClick={() => toggleSection('pending')}
                className="flex justify-between items-center w-full text-left font-medium text-gray-700"
              >
                <span className="flex items-center">
                  {status.migrations?.migrations?.pending > 0
                    ? (
                      <AlertTriangle className="h-4 w-4 text-amber-500 mr-2" />
                    )
                    : (
                      <Check className="h-4 w-4 text-green-500 mr-2" />
                    )}
                  Pending Migrations (
                  {status.migrations?.migrations?.pendingList?.length || 0}
                  )
                </span>
                {expandedSection === 'pending'
                  ? (
                    <ChevronUp className="h-4 w-4 text-gray-500" />
                  )
                  : (
                    <ChevronDown className="h-4 w-4 text-gray-500" />
                  )}
              </button>
            </div>

            {expandedSection === 'pending' && (
              <div className="pl-6">
                {status.migrations?.migrations?.pendingList?.length > 0
                  ? (
                    <>
                      <ul className="mb-4 space-y-1">
                        {status.migrations.migrations.pendingList.map((migration: string) => (
                          <li key={migration} className="text-sm text-gray-700 flex items-center">
                            <span className="w-3 h-3 bg-amber-500 rounded-full mr-2"></span>
                            {migration}
                          </li>
                        ))}
                      </ul>
                      <button
                        onClick={runMigrations}
                        disabled={runningMigration}
                        className="flex items-center px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-sm transition-colors disabled:bg-indigo-300"
                      >
                        {runningMigration
                          ? (
                            <>
                              <RefreshCw className="h-4 w-4 animate-spin mr-2" />
                              Running...
                            </>
                          )
                          : (
                            <>
                              <PlayCircle className="h-4 w-4 mr-2" />
                              Run Migrations
                            </>
                          )}
                      </button>
                      <p className="mt-2 text-xs text-gray-500">
                        Note: Running migrations may cause temporary downtime or service interruption.
                      </p>
                    </>
                  )
                  : (
                    <p className="text-sm text-gray-700">No pending migrations. Your database schema is up to date.</p>
                  )}
              </div>
            )}
          </div>

          <div className="mb-6">
            <div className="border-b pb-2 mb-4">
              <button
                onClick={() => toggleSection('applied')}
                className="flex justify-between items-center w-full text-left font-medium text-gray-700"
              >
                <span className="flex items-center">
                  <Check className="h-4 w-4 text-green-500 mr-2" />
                  Applied Migrations (
                  {status.migrations?.migrations?.appliedList?.length || 0}
                  )
                </span>
                {expandedSection === 'applied'
                  ? (
                    <ChevronUp className="h-4 w-4 text-gray-500" />
                  )
                  : (
                    <ChevronDown className="h-4 w-4 text-gray-500" />
                  )}
              </button>
            </div>

            {expandedSection === 'applied' && (
              <div className="pl-6">
                {status.migrations?.migrations?.appliedList?.length > 0
                  ? (
                    <div className="overflow-x-auto">
                      <table className="min-w-full divide-y divide-gray-200">
                        <thead>
                          <tr>
                            <th className="px-3 py-2 bg-gray-50 text-left text-xs text-gray-500 uppercase tracking-wider">
                              Migration
                            </th>
                            <th className="px-3 py-2 bg-gray-50 text-left text-xs text-gray-500 uppercase tracking-wider">
                              Applied At
                            </th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200">
                          {status.migrations.migrations.appliedList.map((migration: any) => (
                            <tr key={migration.name}>
                              <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-700">{migration.name}</td>
                              <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-700">
                                {new Date(migration.appliedAt).toLocaleString()}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )
                  : (
                    <p className="text-sm text-gray-700">No migrations have been applied yet.</p>
                  )}
              </div>
            )}
          </div>

          <div className="text-sm text-gray-500 flex items-center mt-8 pt-4 border-t">
            <span className="mr-2">Auto migrations:</span>
            {status.autoMigrate
              ? (
                <span className="bg-green-100 text-green-800 px-2 py-0.5 rounded-full text-xs font-medium">Enabled</span>
              )
              : (
                <span className="bg-red-100 text-red-800 px-2 py-0.5 rounded-full text-xs font-medium">Disabled</span>
              )}
          </div>
        </>
      )}
    </div>
  );
}
