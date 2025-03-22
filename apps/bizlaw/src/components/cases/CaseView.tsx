'use client';

import { useState } from 'react';
import Link from 'next/link';
import { FiFileText, FiArrowLeft, FiEdit, FiDownload, FiChevronDown, FiChevronUp } from 'react-icons/fi';
import { CaseType } from '@/lib/db/schema';
import type { Case } from '@/lib/db/schema';

// Define document shape
interface CaseDocument {
  id: string | number;
  title: string;
  documentType: string;
  content?: string | null;
  fileUrl?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// Define the shape of timeline event
interface TimelineEvent {
  date: string;
  description: string;
}

// Define the shape of case details
interface CaseDetails {
  id: number;
  caseId: number;
  plaintiffInfo?: string | null;
  defendantInfo?: string | null;
  legalIssues?: string | null | string[];
  relevantLaws?: string | null;
  // Update timeline to accept both string and array
  timeline?: string | null | TimelineEvent[];
  teachingNotes?: string | null;
  assignmentDetails?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// Define the full case with details and documents
interface CaseWithDetails extends Case {
  details?: CaseDetails;
  documents?: CaseDocument[];
}

// Update the props to use the new type
interface CaseViewProps {
  caseData: CaseWithDetails;
  userRole: string;
}

export default function CaseView({ caseData, userRole }: CaseViewProps) {
  // Now you can use userRole in your component
  const isInstructor = ['professor', 'admin'].includes(userRole);

  const [activeTab, setActiveTab] = useState<'overview' | 'facts' | 'documents'>('overview');
  const [expandedSections, setExpandedSections] = useState<Record<string, boolean>>({
    plaintiff: true,
    defendant: true,
    timeline: true,
    legalIssues: true,
  });

  // Format case type for display
  const formatCaseType = (type: string) => {
    return type
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, c => c.toUpperCase());
  };

  const toggleSection = (section: string) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section],
    }));
  };

  // Determine case type color
  const getCaseTypeColor = (caseType: string) => {
    switch (caseType) {
      case CaseType.SEXUAL_HARASSMENT:
        return 'text-pink-600 bg-pink-100';
      case CaseType.DISCRIMINATION:
        return 'text-purple-600 bg-purple-100';
      case CaseType.WRONGFUL_TERMINATION:
        return 'text-red-600 bg-red-100';
      case CaseType.CONTRACT_DISPUTE:
        return 'text-blue-600 bg-blue-100';
      case CaseType.INTELLECTUAL_PROPERTY:
        return 'text-green-600 bg-green-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  return (
    <>
      <div className="flex items-center mb-6">
        <Link href="/cases" className="text-gray-600 hover:text-gray-900 flex items-center mr-4">
          <FiArrowLeft className="mr-1" /> Back to Cases
        </Link>
        {isInstructor && (
          <Link href={`/admin/cases/${caseData.id}`} className="text-blue-600 hover:text-blue-800 flex items-center">
            <FiEdit className="mr-1" /> Edit Case
          </Link>
        )}
      </div>

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="p-6">
          <div className="flex flex-wrap items-center gap-2 mb-2">
            <span
              className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getCaseTypeColor(caseData.caseType)}`}
            >
              {formatCaseType(caseData.caseType)}
            </span>
            <span className="text-xs text-gray-500">Reference: {caseData.referenceNumber}</span>
          </div>

          <h1 className="text-3xl font-bold mb-4">{caseData.title}</h1>

          {caseData.summary && (
            <div className="mb-8">
              <h2 className="text-xl font-semibold mb-2">Summary</h2>
              <p className="text-gray-700">{caseData.summary}</p>
            </div>
          )}

          {/* Tab Navigation */}
          <div className="border-b border-gray-200 mb-6">
            <nav className="flex space-x-8">
              <button
                onClick={() => setActiveTab('overview')}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'overview'
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                Overview
              </button>
              {caseData.details && (
                <button
                  onClick={() => setActiveTab('facts')}
                  className={`py-4 px-1 border-b-2 font-medium text-sm ${
                    activeTab === 'facts'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  Case Details
                </button>
              )}
              {caseData.documents && caseData.documents.length > 0 && (
                <button
                  onClick={() => setActiveTab('documents')}
                  className={`py-4 px-1 border-b-2 font-medium text-sm ${
                    activeTab === 'documents'
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  Documents ({caseData.documents.length})
                </button>
              )}
            </nav>
          </div>

          {/* Tab Content */}
          <div>
            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <div>
                {caseData.description && (
                  <div className="mb-6">
                    <h2 className="text-xl font-semibold mb-3">Description</h2>
                    <div className="prose max-w-none text-gray-700">
                      {caseData.description.split('\n').map((paragraph: string, i: number) => (
                        <p key={i} className="mb-4">
                          {paragraph}
                        </p>
                      ))}
                    </div>
                  </div>
                )}

                {isInstructor && caseData.details?.assignmentDetails && (
                  <div className="mt-6 border-t pt-6">
                    <h2 className="text-xl font-semibold mb-3 text-blue-600">Assignment Details</h2>
                    <div className="prose max-w-none text-gray-700 bg-blue-50 p-4 rounded-md">
                      {caseData.details.assignmentDetails.split('\n').map((paragraph: string, i: number) => (
                        <p key={i} className="mb-4">
                          {paragraph}
                        </p>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Case Facts Tab */}
            {activeTab === 'facts' && caseData.details && (
              <div>
                {/* Plaintiff Information */}
                {caseData.details.plaintiffInfo && (
                  <div className="mb-6 border border-gray-200 rounded-md">
                    <button
                      onClick={() => toggleSection('plaintiff')}
                      className="w-full flex justify-between items-center p-4 bg-gray-50 hover:bg-gray-100 rounded-t-md"
                    >
                      <h2 className="text-lg font-semibold">Plaintiff Information</h2>
                      {expandedSections.plaintiff ? <FiChevronUp /> : <FiChevronDown />}
                    </button>

                    {expandedSections.plaintiff && (
                      <div className="p-4">
                        <div className="prose max-w-none text-gray-700">
                          {typeof caseData.details.plaintiffInfo === 'string' ? (
                            caseData.details.plaintiffInfo.split('\n').map((paragraph: string, i: number) => (
                              <p key={i} className="mb-4">
                                {paragraph}
                              </p>
                            ))
                          ) : (
                            <pre className="bg-gray-50 p-3 rounded text-sm overflow-auto">
                              {JSON.stringify(caseData.details.plaintiffInfo, null, 2)}
                            </pre>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Defendant Information */}
                {caseData.details.defendantInfo && (
                  <div className="mb-6 border border-gray-200 rounded-md">
                    <button
                      onClick={() => toggleSection('defendant')}
                      className="w-full flex justify-between items-center p-4 bg-gray-50 hover:bg-gray-100 rounded-t-md"
                    >
                      <h2 className="text-lg font-semibold">Defendant Information</h2>
                      {expandedSections.defendant ? <FiChevronUp /> : <FiChevronDown />}
                    </button>

                    {expandedSections.defendant && (
                      <div className="p-4">
                        <div className="prose max-w-none text-gray-700">
                          {typeof caseData.details.defendantInfo === 'string' ? (
                            caseData.details.defendantInfo.split('\n').map((paragraph: string, i: number) => (
                              <p key={i} className="mb-4">
                                {paragraph}
                              </p>
                            ))
                          ) : (
                            <pre className="bg-gray-50 p-3 rounded text-sm overflow-auto">
                              {JSON.stringify(caseData.details.defendantInfo, null, 2)}
                            </pre>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Timeline */}
                {caseData.details.timeline && (
                  <div className="mb-6 border border-gray-200 rounded-md">
                    <button
                      onClick={() => toggleSection('timeline')}
                      className="w-full flex justify-between items-center p-4 bg-gray-50 hover:bg-gray-100 rounded-t-md"
                    >
                      <h2 className="text-lg font-semibold">Timeline of Events</h2>
                      {expandedSections.timeline ? <FiChevronUp /> : <FiChevronDown />}
                    </button>

                    {expandedSections.timeline && (
                      <div className="p-4">
                        <div className="prose max-w-none text-gray-700">
                          {typeof caseData.details.timeline === 'string' ? (
                            caseData.details.timeline.split('\n').map((paragraph: string, i: number) => (
                              <p key={i} className="mb-4">
                                {paragraph}
                              </p>
                            ))
                          ) : Array.isArray(caseData.details.timeline) ? (
                            <ul className="space-y-4 list-none pl-0">
                              {(caseData.details.timeline as TimelineEvent[]).map((event: TimelineEvent, i: number) => (
                                <li key={i} className="border-l-2 border-gray-200 pl-4 ml-4 relative">
                                  <div className="absolute w-3 h-3 bg-blue-500 rounded-full -left-[7px] top-1.5"></div>
                                  <p className="font-medium">{event.date}</p>
                                  <p>{event.description}</p>
                                </li>
                              ))}
                            </ul>
                          ) : (
                            <pre className="bg-gray-50 p-3 rounded text-sm overflow-auto">
                              {JSON.stringify(caseData.details.timeline, null, 2)}
                            </pre>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Legal Issues */}
                {caseData.details.legalIssues && (
                  <div className="mb-6 border border-gray-200 rounded-md">
                    <button
                      onClick={() => toggleSection('legalIssues')}
                      className="w-full flex justify-between items-center p-4 bg-gray-50 hover:bg-gray-100 rounded-t-md"
                    >
                      <h2 className="text-lg font-semibold">Legal Issues</h2>
                      {expandedSections.legalIssues ? <FiChevronUp /> : <FiChevronDown />}
                    </button>

                    {expandedSections.legalIssues && (
                      <div className="p-4">
                        <div className="prose max-w-none text-gray-700">
                          {typeof caseData.details.legalIssues === 'string' ? (
                            caseData.details.legalIssues.split('\n').map((paragraph: string, i: number) => (
                              <p key={i} className="mb-4">
                                {paragraph}
                              </p>
                            ))
                          ) : Array.isArray(caseData.details.legalIssues) ? (
                            <ul className="list-disc pl-5 space-y-2">
                              {(caseData.details.legalIssues as string[]).map((issue: string, i: number) => (
                                <li key={i}>{issue}</li>
                              ))}
                            </ul>
                          ) : (
                            <pre className="bg-gray-50 p-3 rounded text-sm overflow-auto">
                              {JSON.stringify(caseData.details.legalIssues, null, 2)}
                            </pre>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* Instructor Notes - only visible to instructors */}
                {isInstructor && caseData.details.teachingNotes && (
                  <div className="mt-8 border-t border-blue-200 pt-6">
                    <div className="bg-blue-50 p-4 rounded-md">
                      <h2 className="text-lg font-semibold text-blue-700 mb-3">
                        Instructor Notes <span className="text-sm">(Only visible to instructors)</span>
                      </h2>
                      <div className="prose max-w-none text-gray-700">
                        {caseData.details.teachingNotes.split('\n').map((paragraph: string, i: number) => (
                          <p key={i} className="mb-4">
                            {paragraph}
                          </p>
                        ))}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Documents Tab */}
            {activeTab === 'documents' && (
              <div>
                {caseData.documents && caseData.documents.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {caseData.documents.map((doc: CaseDocument) => (
                      <div key={doc.id} className="border border-gray-200 rounded-md p-4 hover:bg-gray-50">
                        <div className="flex items-start">
                          <div className="flex-shrink-0 mr-3">
                            <FiFileText className="h-7 w-7 text-blue-500" />
                          </div>
                          <div className="flex-1">
                            <h3 className="text-lg font-medium mb-1">{doc.title}</h3>
                            <p className="text-sm text-gray-500 mb-3">{doc.documentType.replace(/_/g, ' ')}</p>
                            {doc.fileUrl ? (
                              <a
                                href={doc.fileUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center text-blue-600 hover:text-blue-800"
                              >
                                <FiDownload className="mr-1" /> Download
                              </a>
                            ) : (
                              <Link
                                href={`/cases/${caseData.id}/documents/${doc.id}`}
                                className="inline-flex items-center text-blue-600 hover:text-blue-800"
                              >
                                View Document <span className="ml-1">→</span>
                              </Link>
                            )}
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12 text-gray-500">
                    <FiFileText className="h-12 w-12 mx-auto mb-4 text-gray-400" />
                    <p>No documents available for this case.</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {isInstructor && (
        <div className="mt-4 p-4 bg-blue-50 border-l-4 border-blue-500">
          <h3 className="font-bold">Instructor View</h3>
          <p>You're viewing this as an instructor.</p>
        </div>
      )}
    </>
  );
}

// Also export the props type
export type { CaseViewProps, CaseWithDetails };
