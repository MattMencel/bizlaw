import { Controller } from "@hotwired/stimulus"

// Context Switcher Controller for case/team switching functionality
export default class extends Controller {
  static targets = [
    "trigger", 
    "dropdown", 
    "arrow", 
    "caseName", 
    "teamInfo",
    "searchInput",
    "searchResults",
    "recentItems"
  ]
  
  static values = {
    currentCase: String,
    currentTeam: String,
    apiEndpoint: String
  }

  connect() {
    console.log("Context switcher controller connected")
    this.isOpen = false
    this.setupEventListeners()
    this.loadContextData()
  }

  disconnect() {
    this.removeEventListeners()
  }

  // Setup global event listeners
  setupEventListeners() {
    this.boundClickOutside = this.clickOutside.bind(this)
    this.boundKeyDown = this.keyDown.bind(this)
    
    document.addEventListener('click', this.boundClickOutside)
    document.addEventListener('keydown', this.boundKeyDown)
  }

  // Remove global event listeners
  removeEventListeners() {
    document.removeEventListener('click', this.boundClickOutside)
    document.removeEventListener('keydown', this.boundKeyDown)
  }

  // Toggle dropdown visibility
  toggleDropdown(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      this.closeDropdown()
    } else {
      this.openDropdown()
    }
  }

  // Open dropdown
  openDropdown() {
    this.dropdownTarget.classList.remove('hidden')
    this.arrowTarget.classList.add('rotate-180')
    this.isOpen = true
    
    // Focus search input if present
    if (this.hasSearchInputTarget) {
      setTimeout(() => {
        this.searchInputTarget.focus()
      }, 100)
    }
    
    this.dispatch('opened')
  }

  // Close dropdown
  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
    this.arrowTarget.classList.remove('rotate-180')
    this.isOpen = false
    
    this.dispatch('closed')
  }

  // Handle clicks outside dropdown
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeDropdown()
    }
  }

  // Handle keyboard navigation
  keyDown(event) {
    if (!this.isOpen) return
    
    switch(event.key) {
      case 'Escape':
        event.preventDefault()
        this.closeDropdown()
        this.triggerTarget.focus()
        break
      case 'ArrowUp':
        event.preventDefault()
        this.navigateUp()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.navigateDown()
        break
      case 'Enter':
        event.preventDefault()
        this.selectFocusedItem()
        break
    }
  }

  // Switch to a different case
  async switchCase(event) {
    event.preventDefault()
    const caseId = event.currentTarget.dataset.caseId
    const caseName = event.currentTarget.dataset.caseName
    
    try {
      this.showLoading()
      
      const response = await fetch(`/api/v1/context/switch_case`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ case_id: caseId })
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateContext(data)
        this.addToRecentItems('case', { id: caseId, name: caseName })
        this.closeDropdown()
        
        // Reload page to update content
        window.location.reload()
      } else {
        this.showError('Failed to switch case')
      }
    } catch (error) {
      console.error('Error switching case:', error)
      this.showError('Network error occurred')
    } finally {
      this.hideLoading()
    }
  }

  // Switch to a different team within current case
  async switchTeam(event) {
    event.preventDefault()
    const teamId = event.currentTarget.dataset.teamId
    const teamName = event.currentTarget.dataset.teamName
    
    try {
      this.showLoading()
      
      const response = await fetch(`/api/v1/context/switch_team`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ team_id: teamId })
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateContext(data)
        this.addToRecentItems('team', { id: teamId, name: teamName })
        this.closeDropdown()
        
        // Reload page to update content
        window.location.reload()
      } else {
        this.showError('Failed to switch team')
      }
    } catch (error) {
      console.error('Error switching team:', error)
      this.showError('Network error occurred')
    } finally {
      this.hideLoading()
    }
  }

  // Update context display
  updateContext(data) {
    if (this.hasCaseNameTarget && data.case) {
      this.caseNameTarget.textContent = data.case.title || data.case.name
    }
    
    if (this.hasTeamInfoTarget && data.team) {
      this.teamInfoTarget.textContent = `${data.team.name} • ${data.user_role || 'Student'}`
    }
    
    // Update values
    this.currentCaseValue = data.case?.id || ''
    this.currentTeamValue = data.team?.id || ''
  }

  // Search functionality
  search(event) {
    const query = event.target.value.toLowerCase()
    
    if (query.length < 2) {
      this.clearSearchResults()
      return
    }
    
    this.performSearch(query)
  }

  // Perform search with debouncing
  performSearch(query) {
    clearTimeout(this.searchTimeout)
    
    this.searchTimeout = setTimeout(async () => {
      try {
        const response = await fetch(`/api/v1/context/search?q=${encodeURIComponent(query)}`, {
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': this.getCSRFToken()
          }
        })
        
        if (response.ok) {
          const results = await response.json()
          this.displaySearchResults(results)
        }
      } catch (error) {
        console.error('Search error:', error)
      }
    }, 300)
  }

  // Display search results
  displaySearchResults(results) {
    if (!this.hasSearchResultsTarget) return
    
    let html = ''
    
    if (results.cases && results.cases.length > 0) {
      html += '<div class="px-3 py-1 text-xs font-semibold text-gray-400 uppercase">Cases</div>'
      results.cases.forEach(case_item => {
        html += `
          <button type="button" 
                  class="w-full text-left px-3 py-2 hover:bg-gray-700 rounded-md"
                  data-action="click->context-switcher#switchCase"
                  data-case-id="${case_item.id}"
                  data-case-name="${case_item.title}">
            <div class="font-medium text-white">${case_item.title}</div>
            <div class="text-sm text-gray-300">${case_item.description || ''}</div>
          </button>
        `
      })
    }
    
    if (results.teams && results.teams.length > 0) {
      html += '<div class="px-3 py-1 text-xs font-semibold text-gray-400 uppercase mt-2">Teams</div>'
      results.teams.forEach(team => {
        html += `
          <button type="button" 
                  class="w-full text-left px-3 py-2 hover:bg-gray-700 rounded-md"
                  data-action="click->context-switcher#switchTeam"
                  data-team-id="${team.id}"
                  data-team-name="${team.name}">
            <div class="font-medium text-white">${team.name}</div>
            <div class="text-sm text-gray-300">${team.case_title || ''}</div>
          </button>
        `
      })
    }
    
    if (html === '') {
      html = '<div class="px-3 py-2 text-gray-400 text-sm">No results found</div>'
    }
    
    this.searchResultsTarget.innerHTML = html
  }

  // Clear search results
  clearSearchResults() {
    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.innerHTML = ''
    }
  }

  // Load initial context data
  async loadContextData() {
    try {
      const response = await fetch('/api/v1/context/current', {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateContext(data)
      }
    } catch (error) {
      console.error('Error loading context data:', error)
    }
  }

  // Add item to recent items
  addToRecentItems(type, item) {
    try {
      const key = `recent_${type}s`
      let recent = JSON.parse(localStorage.getItem(key) || '[]')
      
      // Remove if already exists
      recent = recent.filter(r => r.id !== item.id)
      
      // Add to beginning
      recent.unshift(item)
      
      // Keep only 5 most recent
      recent = recent.slice(0, 5)
      
      localStorage.setItem(key, JSON.stringify(recent))
    } catch (error) {
      console.warn('Could not save recent items:', error)
    }
  }

  // Utility methods
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  showLoading() {
    this.triggerTarget.classList.add('opacity-50', 'pointer-events-none')
  }

  hideLoading() {
    this.triggerTarget.classList.remove('opacity-50', 'pointer-events-none')
  }

  showError(message) {
    // Simple error display - could be enhanced with toast notifications
    console.error(message)
    // Could dispatch an event for global error handling
    this.dispatch('error', { detail: { message } })
  }

  // Keyboard navigation helpers
  navigateUp() {
    // Implementation for keyboard navigation
    const focusableElements = this.getFocusableElements()
    const currentIndex = focusableElements.indexOf(document.activeElement)
    const nextIndex = currentIndex > 0 ? currentIndex - 1 : focusableElements.length - 1
    focusableElements[nextIndex]?.focus()
  }

  navigateDown() {
    const focusableElements = this.getFocusableElements()
    const currentIndex = focusableElements.indexOf(document.activeElement)
    const nextIndex = currentIndex < focusableElements.length - 1 ? currentIndex + 1 : 0
    focusableElements[nextIndex]?.focus()
  }

  getFocusableElements() {
    return Array.from(this.dropdownTarget.querySelectorAll('button, a, input'))
  }

  selectFocusedItem() {
    const focused = document.activeElement
    if (focused && focused.tagName === 'BUTTON') {
      focused.click()
    }
  }
}