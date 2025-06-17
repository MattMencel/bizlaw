// Evidence Vault Interface JavaScript
(function() {
  'use strict';

  class EvidenceVault {
    constructor() {
      this.caseId = this.extractCaseId();
      this.currentView = 'list';
      this.selectedDocuments = new Set();
      this.currentPage = 1;
      this.totalPages = 1;
      this.searchTimeout = null;
      this.currentDocument = null;
      
      this.init();
    }

    init() {
      this.bindEvents();
      this.loadDocuments();
      this.loadTagFilters();
    }

    extractCaseId() {
      const pathParts = window.location.pathname.split('/');
      const caseIndex = pathParts.indexOf('cases');
      return caseIndex !== -1 ? pathParts[caseIndex + 1] : null;
    }

    bindEvents() {
      // Search and filter events
      const searchInput = document.getElementById('searchInput');
      if (searchInput) {
        searchInput.addEventListener('input', this.debounceSearch.bind(this));
      }

      const categoryFilter = document.getElementById('categoryFilter');
      if (categoryFilter) {
        categoryFilter.addEventListener('change', this.onFilterChange.bind(this));
      }

      // View mode toggle
      document.querySelectorAll('.view-mode-btn').forEach(btn => {
        btn.addEventListener('click', this.switchViewMode.bind(this));
      });

      // Bulk actions
      const selectAllBtn = document.getElementById('selectAllBtn');
      if (selectAllBtn) {
        selectAllBtn.addEventListener('click', this.toggleSelectAll.bind(this));
      }

      const createBundleBtn = document.getElementById('createBundleBtn');
      if (createBundleBtn) {
        createBundleBtn.addEventListener('click', this.showBundleModal.bind(this));
      }

      // Modal events
      this.bindModalEvents();
    }

    bindModalEvents() {
      // Document preview modal
      const closePreviewBtn = document.getElementById('closePreviewBtn');
      if (closePreviewBtn) {
        closePreviewBtn.addEventListener('click', this.closePreviewModal.bind(this));
      }

      const annotateBtn = document.getElementById('annotateBtn');
      if (annotateBtn) {
        annotateBtn.addEventListener('click', this.showAnnotationModal.bind(this));
      }

      // Annotation modal
      const closeAnnotationBtn = document.getElementById('closeAnnotationBtn');
      const cancelAnnotationBtn = document.getElementById('cancelAnnotationBtn');
      if (closeAnnotationBtn) {
        closeAnnotationBtn.addEventListener('click', this.closeAnnotationModal.bind(this));
      }
      if (cancelAnnotationBtn) {
        cancelAnnotationBtn.addEventListener('click', this.closeAnnotationModal.bind(this));
      }

      const annotationForm = document.getElementById('annotationForm');
      if (annotationForm) {
        annotationForm.addEventListener('submit', this.submitAnnotation.bind(this));
      }

      // Bundle modal
      const closeBundleBtn = document.getElementById('closeBundleBtn');
      const cancelBundleBtn = document.getElementById('cancelBundleBtn');
      if (closeBundleBtn) {
        closeBundleBtn.addEventListener('click', this.closeBundleModal.bind(this));
      }
      if (cancelBundleBtn) {
        cancelBundleBtn.addEventListener('click', this.closeBundleModal.bind(this));
      }

      const bundleForm = document.getElementById('bundleForm');
      if (bundleForm) {
        bundleForm.addEventListener('submit', this.submitBundle.bind(this));
      }

      // Close modals on background click
      document.addEventListener('click', (e) => {
        if (e.target.classList.contains('fixed')) {
          this.closeAllModals();
        }
      });
    }

    debounceSearch() {
      clearTimeout(this.searchTimeout);
      this.searchTimeout = setTimeout(() => {
        this.performSearch();
      }, 300);
    }

    onFilterChange() {
      this.currentPage = 1;
      this.performSearch();
    }

    performSearch() {
      const query = document.getElementById('searchInput')?.value || '';
      const category = document.getElementById('categoryFilter')?.value || '';
      const tags = this.getSelectedTags();

      this.showLoading(true);
      
      const params = new URLSearchParams({
        page: this.currentPage,
        per_page: 25
      });

      if (query) params.append('q', query);
      if (category) params.append('category', category);
      tags.forEach(tag => params.append('tags[]', tag));

      fetch(`/cases/${this.caseId}/evidence_vault/search?${params}`)
        .then(response => response.json())
        .then(data => {
          this.renderDocuments(data.documents);
          this.updateSearchResults(data);
          this.updatePagination(data.pagination);
          this.showLoading(false);
        })
        .catch(error => {
          console.error('Search error:', error);
          this.showError('Failed to search documents');
          this.showLoading(false);
        });
    }

    loadDocuments() {
      this.showLoading(true);
      
      fetch(`/cases/${this.caseId}/evidence_vault.json`)
        .then(response => response.json())
        .then(data => {
          this.renderDocuments(data.documents);
          this.updateStatistics(data);
          this.showLoading(false);
        })
        .catch(error => {
          console.error('Load error:', error);
          this.showError('Failed to load documents');
          this.showLoading(false);
        });
    }

    renderDocuments(documents) {
      const container = document.getElementById('documentsContainer');
      const emptyState = document.getElementById('emptyState');
      
      if (!documents || documents.length === 0) {
        container.innerHTML = '';
        container.appendChild(emptyState);
        return;
      }

      emptyState.style.display = 'none';
      
      if (this.currentView === 'list') {
        this.renderListView(documents, container);
      } else if (this.currentView === 'grid') {
        this.renderGridView(documents, container);
      } else if (this.currentView === 'timeline') {
        this.renderTimelineView(documents, container);
      }
    }

    renderListView(documents, container) {
      const html = `
        <div class="overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <input type="checkbox" id="selectAllCheckbox" class="h-4 w-4 text-blue-600 border-gray-300 rounded">
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Document</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tags</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Annotations</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              ${documents.map(doc => this.renderDocumentRow(doc)).join('')}
            </tbody>
          </table>
        </div>
      `;
      container.innerHTML = html;
      this.bindDocumentEvents();
    }

    renderDocumentRow(doc) {
      const truncatedDescription = doc.description && doc.description.length > 100 
        ? doc.description.substring(0, 100) + '...' 
        : doc.description || '';

      return `
        <tr class="hover:bg-gray-50">
          <td class="px-6 py-4 whitespace-nowrap">
            <input type="checkbox" class="document-checkbox h-4 w-4 text-blue-600 border-gray-300 rounded" 
                   data-document-id="${doc.id}">
          </td>
          <td class="px-6 py-4">
            <div class="flex items-center">
              <div class="flex-shrink-0 h-10 w-10">
                <div class="h-10 w-10 rounded-lg bg-blue-100 flex items-center justify-center">
                  <svg class="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                </div>
              </div>
              <div class="ml-4">
                <div class="text-sm font-medium text-gray-900">
                  <button class="text-left hover:text-blue-600 document-title" data-document-id="${doc.id}">
                    ${this.escapeHtml(doc.title)}
                  </button>
                </div>
                <div class="text-sm text-gray-500">${this.escapeHtml(truncatedDescription)}</div>
              </div>
            </div>
          </td>
          <td class="px-6 py-4 whitespace-nowrap">
            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              ${this.formatCategory(doc.category)}
            </span>
          </td>
          <td class="px-6 py-4">
            <div class="flex flex-wrap gap-1">
              ${(doc.tags || []).slice(0, 3).map(tag => 
                `<span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-800">${this.escapeHtml(tag)}</span>`
              ).join('')}
              ${doc.tags && doc.tags.length > 3 ? `<span class="text-xs text-gray-500">+${doc.tags.length - 3} more</span>` : ''}
            </div>
          </td>
          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
            ${doc.annotation_count > 0 ? 
              `<span class="inline-flex items-center text-yellow-600">
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                </svg>
                ${doc.annotation_count}
              </span>` : '-'
            }
          </td>
          <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
            <button class="text-blue-600 hover:text-blue-900 mr-3 preview-document" data-document-id="${doc.id}">
              Preview
            </button>
            ${doc.can_annotate ? 
              `<button class="text-green-600 hover:text-green-900 mr-3 annotate-document" data-document-id="${doc.id}">
                Annotate
              </button>` : ''
            }
            <a href="${doc.download_url}" class="text-purple-600 hover:text-purple-900" download>
              Download
            </a>
          </td>
        </tr>
      `;
    }

    renderGridView(documents, container) {
      const html = `
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          ${documents.map(doc => this.renderDocumentCard(doc)).join('')}
        </div>
      `;
      container.innerHTML = html;
      this.bindDocumentEvents();
    }

    renderDocumentCard(doc) {
      const truncatedDescription = doc.description && doc.description.length > 150 
        ? doc.description.substring(0, 150) + '...' 
        : doc.description || '';

      return `
        <div class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-shadow">
          <div class="p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="flex-shrink-0">
                <div class="h-12 w-12 rounded-lg bg-blue-100 flex items-center justify-center">
                  <svg class="h-6 w-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                </div>
              </div>
              <input type="checkbox" class="document-checkbox h-4 w-4 text-blue-600 border-gray-300 rounded" 
                     data-document-id="${doc.id}">
            </div>
            
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              <button class="text-left hover:text-blue-600 document-title" data-document-id="${doc.id}">
                ${this.escapeHtml(doc.title)}
              </button>
            </h3>
            
            <p class="text-sm text-gray-500 mb-4">${this.escapeHtml(truncatedDescription)}</p>
            
            <div class="mb-4">
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                ${this.formatCategory(doc.category)}
              </span>
              ${doc.annotation_count > 0 ? 
                `<span class="ml-2 inline-flex items-center text-yellow-600 text-xs">
                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
                  </svg>
                  ${doc.annotation_count}
                </span>` : ''
              }
            </div>
            
            <div class="mb-4">
              <div class="flex flex-wrap gap-1">
                ${(doc.tags || []).slice(0, 3).map(tag => 
                  `<span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-800">${this.escapeHtml(tag)}</span>`
                ).join('')}
                ${doc.tags && doc.tags.length > 3 ? `<span class="text-xs text-gray-500">+${doc.tags.length - 3} more</span>` : ''}
              </div>
            </div>
            
            <div class="flex items-center space-x-3">
              <button class="text-blue-600 hover:text-blue-900 text-sm font-medium preview-document" data-document-id="${doc.id}">
                Preview
              </button>
              ${doc.can_annotate ? 
                `<button class="text-green-600 hover:text-green-900 text-sm font-medium annotate-document" data-document-id="${doc.id}">
                  Annotate
                </button>` : ''
              }
              <a href="${doc.download_url}" class="text-purple-600 hover:text-purple-900 text-sm font-medium" download>
                Download
              </a>
            </div>
          </div>
        </div>
      `;
    }

    bindDocumentEvents() {
      // Document selection
      document.querySelectorAll('.document-checkbox').forEach(checkbox => {
        checkbox.addEventListener('change', this.onDocumentSelect.bind(this));
      });

      // Document preview
      document.querySelectorAll('.document-title, .preview-document').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const documentId = e.target.getAttribute('data-document-id');
          this.previewDocument(documentId);
        });
      });

      // Document annotation
      document.querySelectorAll('.annotate-document').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const documentId = e.target.getAttribute('data-document-id');
          this.currentDocument = documentId;
          this.showAnnotationModal();
        });
      });

      // Select all checkbox
      const selectAllCheckbox = document.getElementById('selectAllCheckbox');
      if (selectAllCheckbox) {
        selectAllCheckbox.addEventListener('change', this.toggleSelectAll.bind(this));
      }
    }

    onDocumentSelect() {
      this.updateSelectedDocuments();
      this.updateBulkActionButton();
    }

    updateSelectedDocuments() {
      this.selectedDocuments.clear();
      document.querySelectorAll('.document-checkbox:checked').forEach(checkbox => {
        this.selectedDocuments.add(checkbox.getAttribute('data-document-id'));
      });
    }

    updateBulkActionButton() {
      const createBundleBtn = document.getElementById('createBundleBtn');
      if (createBundleBtn) {
        createBundleBtn.disabled = this.selectedDocuments.size === 0;
      }
    }

    toggleSelectAll() {
      const selectAllCheckbox = document.getElementById('selectAllCheckbox');
      const isChecked = selectAllCheckbox?.checked || false;
      
      document.querySelectorAll('.document-checkbox').forEach(checkbox => {
        checkbox.checked = isChecked;
      });
      
      this.updateSelectedDocuments();
      this.updateBulkActionButton();
    }

    switchViewMode(e) {
      document.querySelectorAll('.view-mode-btn').forEach(btn => {
        btn.classList.remove('active', 'bg-blue-100', 'text-blue-700');
      });
      
      e.target.classList.add('active', 'bg-blue-100', 'text-blue-700');
      
      if (e.target.id === 'listViewBtn') {
        this.currentView = 'list';
      } else if (e.target.id === 'gridViewBtn') {
        this.currentView = 'grid';
      } else if (e.target.id === 'timelineViewBtn') {
        this.currentView = 'timeline';
      }
      
      this.performSearch(); // Re-render with current view
    }

    previewDocument(documentId) {
      fetch(`/cases/${this.caseId}/evidence_vault/${documentId}`)
        .then(response => response.json())
        .then(data => {
          this.showPreviewModal(data);
        })
        .catch(error => {
          console.error('Preview error:', error);
          this.showError('Failed to load document preview');
        });
    }

    showPreviewModal(document) {
      this.currentDocument = document.id;
      
      document.getElementById('previewTitle').textContent = document.title;
      
      const previewContent = document.getElementById('previewContent');
      previewContent.innerHTML = `
        <div class="mb-4">
          <p class="text-sm text-gray-600 mb-2"><strong>Description:</strong> ${this.escapeHtml(document.description || 'No description')}</p>
          <p class="text-sm text-gray-600 mb-2"><strong>Category:</strong> ${this.formatCategory(document.category)}</p>
          <p class="text-sm text-gray-600 mb-2"><strong>Created by:</strong> ${this.escapeHtml(document.created_by.name)}</p>
          <p class="text-sm text-gray-600 mb-4"><strong>Created:</strong> ${new Date(document.created_at).toLocaleDateString()}</p>
          
          ${document.tags && document.tags.length > 0 ? `
            <div class="mb-4">
              <p class="text-sm text-gray-600 mb-2"><strong>Tags:</strong></p>
              <div class="flex flex-wrap gap-1">
                ${document.tags.map(tag => 
                  `<span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-100 text-blue-800">${this.escapeHtml(tag)}</span>`
                ).join('')}
              </div>
            </div>
          ` : ''}
          
          ${document.annotations && document.annotations.length > 0 ? `
            <div class="mb-4">
              <p class="text-sm text-gray-600 mb-2"><strong>Annotations:</strong></p>
              <div class="max-h-40 overflow-y-auto space-y-2">
                ${document.annotations.map(annotation => `
                  <div class="bg-yellow-50 border-l-4 border-yellow-400 p-3">
                    <div class="text-sm">
                      <p class="text-gray-700">${this.escapeHtml(annotation.content)}</p>
                      <p class="text-gray-500 mt-1 text-xs">
                        Page ${annotation.page} • ${annotation.user_name} • ${new Date(annotation.created_at).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                `).join('')}
              </div>
            </div>
          ` : ''}
        </div>
      `;
      
      // Update action buttons
      document.getElementById('downloadBtn').onclick = () => {
        window.open(document.download_url, '_blank');
      };
      
      const annotateBtn = document.getElementById('annotateBtn');
      if (document.can_annotate) {
        annotateBtn.style.display = 'inline-block';
        annotateBtn.onclick = () => {
          this.closePreviewModal();
          this.showAnnotationModal();
        };
      } else {
        annotateBtn.style.display = 'none';
      }
      
      document.getElementById('documentPreviewModal').classList.remove('hidden');
    }

    closePreviewModal() {
      document.getElementById('documentPreviewModal').classList.add('hidden');
    }

    showAnnotationModal() {
      document.getElementById('annotationModal').classList.remove('hidden');
      document.getElementById('annotationContent').focus();
    }

    closeAnnotationModal() {
      document.getElementById('annotationModal').classList.add('hidden');
      document.getElementById('annotationForm').reset();
    }

    submitAnnotation(e) {
      e.preventDefault();
      
      const content = document.getElementById('annotationContent').value.trim();
      const page = parseInt(document.getElementById('annotationPage').value) || 1;
      
      if (!content) {
        this.showError('Annotation content is required');
        return;
      }
      
      fetch(`/cases/${this.caseId}/evidence_vault/${this.currentDocument}/annotate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        },
        body: JSON.stringify({
          annotation: {
            content: content,
            page: page
          }
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          this.closeAnnotationModal();
          this.showSuccess('Annotation added successfully');
          this.performSearch(); // Refresh the document list
        } else {
          this.showError(data.errors ? data.errors.join(', ') : 'Failed to add annotation');
        }
      })
      .catch(error => {
        console.error('Annotation error:', error);
        this.showError('Failed to add annotation');
      });
    }

    showBundleModal() {
      if (this.selectedDocuments.size === 0) {
        this.showError('Please select at least one document to create a bundle');
        return;
      }
      
      const selectedDocumentsDiv = document.getElementById('selectedDocuments');
      selectedDocumentsDiv.innerHTML = `
        <p class="text-sm text-gray-600 mb-2">${this.selectedDocuments.size} documents selected:</p>
        ${Array.from(this.selectedDocuments).map(id => {
          const checkbox = document.querySelector(`[data-document-id="${id}"]`);
          const row = checkbox?.closest('tr') || checkbox?.closest('.bg-white');
          const title = row?.querySelector('.document-title')?.textContent || 'Unknown Document';
          return `<div class="text-sm text-gray-700">• ${this.escapeHtml(title)}</div>`;
        }).join('')}
      `;
      
      document.getElementById('bundleModal').classList.remove('hidden');
      document.getElementById('bundleName').focus();
    }

    closeBundleModal() {
      document.getElementById('bundleModal').classList.add('hidden');
      document.getElementById('bundleForm').reset();
    }

    submitBundle(e) {
      e.preventDefault();
      
      const name = document.getElementById('bundleName').value.trim();
      
      if (!name) {
        this.showError('Bundle name is required');
        return;
      }
      
      fetch(`/cases/${this.caseId}/evidence_vault/bundles`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
        },
        body: JSON.stringify({
          bundle: {
            name: name,
            document_ids: Array.from(this.selectedDocuments)
          }
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.name) {
          this.closeBundleModal();
          this.showSuccess(`Evidence bundle "${data.name}" created successfully`);
          this.selectedDocuments.clear();
          this.updateBulkActionButton();
          document.querySelectorAll('.document-checkbox').forEach(cb => cb.checked = false);
        } else {
          this.showError(data.errors ? data.errors.join(', ') : 'Failed to create bundle');
        }
      })
      .catch(error => {
        console.error('Bundle error:', error);
        this.showError('Failed to create bundle');
      });
    }

    closeAllModals() {
      document.getElementById('documentPreviewModal')?.classList.add('hidden');
      document.getElementById('annotationModal')?.classList.add('hidden');
      document.getElementById('bundleModal')?.classList.add('hidden');
    }

    getSelectedTags() {
      // This would be implemented when tag filtering UI is added
      return [];
    }

    loadTagFilters() {
      // This would load available tags for filtering
      // Placeholder for tag filter UI
    }

    updateSearchResults(data) {
      const searchResults = document.getElementById('searchResults');
      if (searchResults) {
        if (data.search_query) {
          searchResults.textContent = `${data.total_results} results for "${data.search_query}"`;
        } else {
          searchResults.textContent = `${data.total_results} documents`;
        }
      }
    }

    updateStatistics(data) {
      const totalDocs = document.getElementById('totalDocuments');
      const totalCategories = document.getElementById('totalCategories');
      const annotatedDocs = document.getElementById('annotatedDocuments');
      
      if (totalDocs) totalDocs.textContent = data.total_documents || 0;
      if (totalCategories) totalCategories.textContent = Object.keys(data.document_categories || {}).length;
      if (annotatedDocs) {
        const annotated = data.documents?.filter(doc => doc.annotation_count > 0).length || 0;
        annotatedDocs.textContent = annotated;
      }
    }

    updatePagination(pagination) {
      // Implement pagination UI updates
      // This would update the pagination controls based on the pagination data
    }

    showLoading(show) {
      const loadingIndicator = document.getElementById('loadingIndicator');
      if (loadingIndicator) {
        loadingIndicator.classList.toggle('hidden', !show);
      }
    }

    showError(message) {
      // Implement error notification
      console.error(message);
      // You could integrate with your existing notification system here
    }

    showSuccess(message) {
      // Implement success notification
      console.log(message);
      // You could integrate with your existing notification system here
    }

    formatCategory(category) {
      return category ? category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()) : 'Uncategorized';
    }

    escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  }

  // Initialize when DOM is loaded
  document.addEventListener('DOMContentLoaded', () => {
    if (window.location.pathname.includes('/evidence_vault')) {
      new EvidenceVault();
    }
  });

})();