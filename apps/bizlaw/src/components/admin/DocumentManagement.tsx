'use client';

import { useState, useEffect } from 'react';
import { FiPlus, FiEdit, FiTrash2, FiDownload, FiFileText, FiFile } from 'react-icons/fi';

interface Document {
  id: string;
  title: string;
  documentType: string;
  content: string | null;
  fileUrl: string | null;
  createdAt: string;
  updatedAt: string;
}

interface DocumentManagementProps {
  caseId: string;
  documents?: Document[];
}

interface DocumentProps {
  caseId: string;
  documents: Array<{
    id: string | number;
    // Other fields...
  }>;
}

export default function DocumentManagement({ caseId, documents: initialDocuments = [] }: DocumentManagementProps) {
  const [documents, setDocuments] = useState<Document[]>(initialDocuments);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [editingDoc, setEditingDoc] = useState<Document | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    documentType: 'brief',
    content: '',
    fileUrl: '',
  });

  // Fetch documents on load
  useEffect(() => {
    fetchDocuments();
  }, [caseId]);

  async function fetchDocuments() {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`/api/cases/${caseId}/documents`);

      if (!response.ok) {
        throw new Error(`Failed to fetch documents: ${response.statusText}`);
      }

      const data = await response.json();
      setDocuments(data);
    } catch (err) {
      console.error('Error fetching documents:', err);
      setError('Failed to load documents');
    } finally {
      setLoading(false);
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const resetForm = () => {
    setFormData({
      title: '',
      documentType: 'brief',
      content: '',
      fileUrl: '',
    });
    setEditingDoc(null);
    setShowForm(false);
  };

  const editDocument = (doc: Document) => {
    setFormData({
      title: doc.title,
      documentType: doc.documentType,
      content: doc.content || '',
      fileUrl: doc.fileUrl || '',
    });
    setEditingDoc(doc);
    setShowForm(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      let response;

      if (editingDoc) {
        // Update existing document
        response = await fetch(`/api/cases/${caseId}/documents/${editingDoc.id}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(formData),
        });
      } else {
        // Create new document
        response = await fetch(`/api/cases/${caseId}/documents`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(formData),
        });
      }

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to save document');
      }

      // Refresh documents list
      await fetchDocuments();
      resetForm();
    } catch (err) {
      console.error('Error saving document:', err);
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  const deleteDocument = async (id: string) => {
    if (!confirm('Are you sure you want to delete this document?')) {
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`/api/cases/${caseId}/documents/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete document');
      }

      // Remove from state
      setDocuments(documents.filter(doc => doc.id !== id));
    } catch (err) {
      console.error('Error deleting document:', err);
      setError(err instanceof Error ? err.message : 'Failed to delete document');
    } finally {
      setLoading(false);
    }
  };

  // Document type options
  const documentTypes = [
    { value: 'brief', label: 'Legal Brief' },
    { value: 'complaint', label: 'Complaint' },
    { value: 'answer', label: 'Answer' },
    { value: 'motion', label: 'Motion' },
    { value: 'exhibit', label: 'Exhibit' },
    { value: 'transcript', label: 'Transcript' },
    { value: 'opinion', label: 'Court Opinion' },
    { value: 'other', label: 'Other' },
  ];

  if (loading && documents.length === 0) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-4 text-red-700">
          <p>{error}</p>
        </div>
      )}

      <div className="flex justify-between mb-6">
        <h2 className="text-xl font-semibold">Case Documents</h2>
        <button
          onClick={() => setShowForm(!showForm)}
          className={`flex items-center px-4 py-2 rounded-md text-sm font-medium ${
            showForm ? 'bg-gray-200 text-gray-700 hover:bg-gray-300' : 'bg-blue-600 text-white hover:bg-blue-700'
          }`}
        >
          {showForm ? (
            'Cancel'
          ) : (
            <>
              <FiPlus className="mr-2" /> Add Document
            </>
          )}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} className="mb-8 border border-gray-200 rounded-lg p-6 bg-gray-50">
          <h3 className="text-lg font-medium mb-4">{editingDoc ? 'Edit Document' : 'Add New Document'}</h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
                Title <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="title"
                name="title"
                value={formData.title}
                onChange={handleChange}
                required
                className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label htmlFor="documentType" className="block text-sm font-medium text-gray-700 mb-1">
                Document Type <span className="text-red-500">*</span>
              </label>
              <select
                id="documentType"
                name="documentType"
                value={formData.documentType}
                onChange={handleChange}
                required
                className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {documentTypes.map(type => (
                  <option key={type.value} value={type.value}>
                    {type.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="mb-6">
            <label htmlFor="content" className="block text-sm font-medium text-gray-700 mb-1">
              Document Content
            </label>
            <textarea
              id="content"
              name="content"
              value={formData.content}
              onChange={handleChange}
              rows={10}
              className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter document text content here..."
            />
          </div>

          <div className="mb-6">
            <label htmlFor="fileUrl" className="block text-sm font-medium text-gray-700 mb-1">
              File URL
            </label>
            <input
              type="url"
              id="fileUrl"
              name="fileUrl"
              value={formData.fileUrl || ''}
              onChange={handleChange}
              className="block w-full rounded-md border border-gray-300 py-2 px-3 focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="https://example.com/file.pdf"
            />
            <p className="mt-1 text-xs text-gray-500">Enter a URL to an external file (PDF, DOCX, etc.)</p>
          </div>

          <div className="flex justify-end space-x-3">
            <button
              type="button"
              onClick={resetForm}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className={`px-4 py-2 rounded-md text-sm font-medium text-white ${
                loading ? 'bg-blue-400' : 'bg-blue-600 hover:bg-blue-700'
              }`}
            >
              {loading ? 'Saving...' : editingDoc ? 'Update Document' : 'Add Document'}
            </button>
          </div>
        </form>
      )}

      {documents.length === 0 ? (
        <div className="text-center py-8 bg-gray-50 border border-dashed border-gray-300 rounded-lg">
          <FiFileText className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No documents</h3>
          <p className="mt-1 text-sm text-gray-500">Get started by adding a new document.</p>
          <div className="mt-6">
            <button
              type="button"
              onClick={() => setShowForm(true)}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              <FiPlus className="-ml-1 mr-2 h-5 w-5" />
              New Document
            </button>
          </div>
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th
                  scope="col"
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Document
                </th>
                <th
                  scope="col"
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Type
                </th>
                <th
                  scope="col"
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Date
                </th>
                <th
                  scope="col"
                  className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {documents.map(doc => (
                <tr key={doc.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="flex items-center">
                      {doc.fileUrl ? (
                        <FiFile className="flex-shrink-0 h-5 w-5 text-gray-500 mr-3" />
                      ) : (
                        <FiFileText className="flex-shrink-0 h-5 w-5 text-blue-500 mr-3" />
                      )}
                      <div>
                        <div className="text-sm font-medium text-gray-900">{doc.title}</div>
                        <div className="text-xs text-gray-500">
                          {doc.content ? `${doc.content.slice(0, 50)}...` : 'No text content'}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      {documentTypes.find(t => t.value === doc.documentType)?.label || doc.documentType}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-500">{new Date(doc.createdAt).toLocaleDateString()}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex space-x-3">
                      <button onClick={() => editDocument(doc)} className="text-blue-600 hover:text-blue-900">
                        <FiEdit className="h-5 w-5" title="Edit" />
                      </button>

                      {doc.fileUrl && (
                        <a
                          href={doc.fileUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-green-600 hover:text-green-900"
                        >
                          <FiDownload className="h-5 w-5" title="Download" />
                        </a>
                      )}

                      <button onClick={() => deleteDocument(doc.id)} className="text-red-600 hover:text-red-900">
                        <FiTrash2 className="h-5 w-5" title="Delete" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
