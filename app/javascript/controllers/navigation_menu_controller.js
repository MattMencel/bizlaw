import { Controller } from "@hotwired/stimulus"

// Navigation Menu Controller for hierarchical collapsible navigation
export default class extends Controller {
  static targets = [
    "section", 
    "sectionToggle", 
    "sectionArrow", 
    "sectionContent",
    "subsectionToggle", 
    "subsectionArrow", 
    "subsectionContent"
  ]
  
  static values = {
    persistState: { type: Boolean, default: true },
    animationDuration: { type: Number, default: 200 }
  }

  connect() {
    console.log("Navigation menu controller connected")
    this.initializeState()
    this.restoreNavigationState()
  }

  // Initialize section states
  initializeState() {
    this.sectionStates = new Map()
    this.subsectionStates = new Map()
    
    // Set default expanded state for all sections
    this.sectionTargets.forEach((section, index) => {
      const sectionId = this.getSectionId(section)
      this.sectionStates.set(sectionId, true) // Default to expanded
    })
  }

  // Toggle main section visibility
  toggleSection(event) {
    event.preventDefault()
    const sectionId = event.params.section
    const isExpanded = this.sectionStates.get(sectionId)
    
    this.setSectionState(sectionId, !isExpanded)
    this.animateSection(sectionId, !isExpanded)
    
    if (this.persistStateValue) {
      this.saveNavigationState()
    }
  }

  // Toggle subsection visibility
  toggleSubsection(event) {
    event.preventDefault()
    const subsectionId = event.params.subsection
    const isExpanded = this.subsectionStates.get(subsectionId) ?? true
    
    this.setSubsectionState(subsectionId, !isExpanded)
    this.animateSubsection(subsectionId, !isExpanded)
    
    if (this.persistStateValue) {
      this.saveNavigationState()
    }
  }

  // Set section expanded/collapsed state
  setSectionState(sectionId, isExpanded) {
    this.sectionStates.set(sectionId, isExpanded)
    
    const toggle = this.findSectionToggle(sectionId)
    const arrow = this.findSectionArrow(sectionId)
    
    if (toggle) {
      toggle.setAttribute('aria-expanded', isExpanded.toString())
    }
    
    if (arrow) {
      if (isExpanded) {
        arrow.classList.remove('rotate-180')
      } else {
        arrow.classList.add('rotate-180')
      }
    }
  }

  // Set subsection expanded/collapsed state
  setSubsectionState(subsectionId, isExpanded) {
    this.subsectionStates.set(subsectionId, isExpanded)
    
    const toggle = this.findSubsectionToggle(subsectionId)
    const arrow = this.findSubsectionArrow(subsectionId)
    
    if (toggle) {
      toggle.setAttribute('aria-expanded', isExpanded.toString())
    }
    
    if (arrow) {
      if (isExpanded) {
        arrow.classList.remove('rotate-180')
      } else {
        arrow.classList.add('rotate-180')
      }
    }
  }

  // Animate section expand/collapse
  animateSection(sectionId, isExpanded) {
    const content = document.getElementById(`${sectionId}-content`)
    if (!content) return

    if (isExpanded) {
      this.expandElement(content)
    } else {
      this.collapseElement(content)
    }
  }

  // Animate subsection expand/collapse
  animateSubsection(subsectionId, isExpanded) {
    const content = document.getElementById(`${subsectionId}-content`)
    if (!content) return

    if (isExpanded) {
      this.expandElement(content)
    } else {
      this.collapseElement(content)
    }
  }

  // Expand element with animation
  expandElement(element) {
    element.style.display = 'block'
    element.style.height = '0px'
    element.style.overflow = 'hidden'
    element.style.transition = `height ${this.animationDurationValue}ms ease-in-out`
    
    // Force a reflow
    element.offsetHeight
    
    const targetHeight = element.scrollHeight
    element.style.height = `${targetHeight}px`
    
    setTimeout(() => {
      element.style.height = 'auto'
      element.style.overflow = 'visible'
      element.style.transition = ''
    }, this.animationDurationValue)
  }

  // Collapse element with animation
  collapseElement(element) {
    const startHeight = element.offsetHeight
    element.style.height = `${startHeight}px`
    element.style.overflow = 'hidden'
    element.style.transition = `height ${this.animationDurationValue}ms ease-in-out`
    
    // Force a reflow
    element.offsetHeight
    
    element.style.height = '0px'
    
    setTimeout(() => {
      element.style.display = 'none'
      element.style.height = ''
      element.style.overflow = ''
      element.style.transition = ''
    }, this.animationDurationValue)
  }

  // Helper methods for finding elements
  getSectionId(sectionElement) {
    const toggle = sectionElement.querySelector('[data-navigation-menu-target="sectionToggle"]')
    return toggle ? toggle.getAttribute('data-navigation-menu-section-param') : null
  }

  findSectionToggle(sectionId) {
    return this.sectionToggleTargets.find(toggle => 
      toggle.getAttribute('data-navigation-menu-section-param') === sectionId
    )
  }

  findSectionArrow(sectionId) {
    const toggle = this.findSectionToggle(sectionId)
    return toggle ? toggle.querySelector('[data-navigation-menu-target="sectionArrow"]') : null
  }

  findSubsectionToggle(subsectionId) {
    return this.subsectionToggleTargets.find(toggle => 
      toggle.getAttribute('data-navigation-menu-subsection-param') === subsectionId
    )
  }

  findSubsectionArrow(subsectionId) {
    const toggle = this.findSubsectionToggle(subsectionId)
    return toggle ? toggle.querySelector('[data-navigation-menu-target="subsectionArrow"]') : null
  }

  // Keyboard navigation support
  handleKeyDown(event) {
    switch(event.key) {
      case 'ArrowUp':
        event.preventDefault()
        this.navigateUp()
        break
      case 'ArrowDown':
        event.preventDefault()
        this.navigateDown()
        break
      case 'Enter':
      case ' ':
        event.preventDefault()
        this.activateCurrentItem()
        break
      case 'Escape':
        event.preventDefault()
        this.closeAllSections()
        break
    }
  }

  // Save navigation state to localStorage
  saveNavigationState() {
    const state = {
      sections: Object.fromEntries(this.sectionStates),
      subsections: Object.fromEntries(this.subsectionStates),
      timestamp: Date.now()
    }
    
    try {
      localStorage.setItem('navigation_state', JSON.stringify(state))
    } catch (error) {
      console.warn('Could not save navigation state:', error)
    }
  }

  // Restore navigation state from localStorage
  restoreNavigationState() {
    if (!this.persistStateValue) return
    
    try {
      const savedState = localStorage.getItem('navigation_state')
      if (!savedState) return
      
      const state = JSON.parse(savedState)
      
      // Only restore if saved within last 24 hours
      if (Date.now() - state.timestamp > 24 * 60 * 60 * 1000) {
        return
      }
      
      // Restore section states
      Object.entries(state.sections).forEach(([sectionId, isExpanded]) => {
        this.setSectionState(sectionId, isExpanded)
        this.animateSection(sectionId, isExpanded)
      })
      
      // Restore subsection states
      Object.entries(state.subsections).forEach(([subsectionId, isExpanded]) => {
        this.setSubsectionState(subsectionId, isExpanded)
        this.animateSubsection(subsectionId, isExpanded)
      })
      
    } catch (error) {
      console.warn('Could not restore navigation state:', error)
    }
  }

  // Expand all sections
  expandAll() {
    this.sectionStates.forEach((_, sectionId) => {
      this.setSectionState(sectionId, true)
      this.animateSection(sectionId, true)
    })
    
    this.subsectionStates.forEach((_, subsectionId) => {
      this.setSubsectionState(subsectionId, true)
      this.animateSubsection(subsectionId, true)
    })
    
    if (this.persistStateValue) {
      this.saveNavigationState()
    }
  }

  // Collapse all sections
  collapseAll() {
    this.sectionStates.forEach((_, sectionId) => {
      this.setSectionState(sectionId, false)
      this.animateSection(sectionId, false)
    })
    
    this.subsectionStates.forEach((_, subsectionId) => {
      this.setSubsectionState(subsectionId, false)
      this.animateSubsection(subsectionId, false)
    })
    
    if (this.persistStateValue) {
      this.saveNavigationState()
    }
  }
}