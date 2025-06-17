import { Controller } from "@hotwired/stimulus"

// Mobile Navigation Controller for responsive navigation behavior
export default class extends Controller {
  static targets = ["menu", "overlay", "toggle"]
  
  static classes = ["open", "closed"]
  
  connect() {
    console.log("Mobile navigation controller connected")
    this.isOpen = false
    this.setupEventListeners()
    this.checkScreenSize()
  }

  disconnect() {
    this.removeEventListeners()
  }

  // Setup event listeners
  setupEventListeners() {
    this.boundResize = this.handleResize.bind(this)
    this.boundKeyDown = this.handleKeyDown.bind(this)
    this.boundClickOutside = this.clickOutside.bind(this)
    
    window.addEventListener('resize', this.boundResize)
    document.addEventListener('keydown', this.boundKeyDown)
    document.addEventListener('click', this.boundClickOutside)
  }

  // Remove event listeners
  removeEventListeners() {
    window.removeEventListener('resize', this.boundResize)
    document.removeEventListener('keydown', this.boundKeyDown)
    document.removeEventListener('click', this.boundClickOutside)
  }

  // Toggle mobile menu
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  // Open mobile menu
  open() {
    if (this.isOpen) return
    
    this.isOpen = true
    
    // Show menu and overlay
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove('hidden')
      this.menuTarget.classList.add('fixed', 'inset-0', 'z-50', 'bg-gray-800')
      
      // Animate in
      requestAnimationFrame(() => {
        this.menuTarget.classList.add('transition-transform', 'duration-300')
        this.menuTarget.classList.remove('transform', '-translate-x-full')
      })
    }
    
    // Show overlay
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('hidden')
      this.overlayTarget.classList.add('opacity-0')
      
      requestAnimationFrame(() => {
        this.overlayTarget.classList.add('transition-opacity', 'duration-300')
        this.overlayTarget.classList.remove('opacity-0')
        this.overlayTarget.classList.add('opacity-50')
      })
    }
    
    // Update toggle button
    this.updateToggleButton(true)
    
    // Prevent body scroll
    document.body.style.overflow = 'hidden'
    
    // Focus management
    this.trapFocus()
    
    this.dispatch('opened')
  }

  // Close mobile menu
  close() {
    if (!this.isOpen) return
    
    this.isOpen = false
    
    // Animate out menu
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('transform', '-translate-x-full')
      
      setTimeout(() => {
        this.menuTarget.classList.add('hidden')
        this.menuTarget.classList.remove('fixed', 'inset-0', 'z-50', 'bg-gray-800')
        this.menuTarget.classList.remove('transition-transform', 'duration-300', 'transform', '-translate-x-full')
      }, 300)
    }
    
    // Hide overlay
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove('opacity-50')
      this.overlayTarget.classList.add('opacity-0')
      
      setTimeout(() => {
        this.overlayTarget.classList.add('hidden')
        this.overlayTarget.classList.remove('transition-opacity', 'duration-300', 'opacity-0')
      }, 300)
    }
    
    // Update toggle button
    this.updateToggleButton(false)
    
    // Restore body scroll
    document.body.style.overflow = ''
    
    // Return focus to toggle
    if (this.hasToggleTarget) {
      this.toggleTarget.focus()
    }
    
    this.dispatch('closed')
  }

  // Update toggle button appearance
  updateToggleButton(isOpen) {
    if (!this.hasToggleTarget) return
    
    const icon = this.toggleTarget.querySelector('svg')
    if (!icon) return
    
    if (isOpen) {
      // Change to X icon
      icon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
      `
      this.toggleTarget.setAttribute('aria-expanded', 'true')
      this.toggleTarget.setAttribute('aria-label', 'Close navigation menu')
    } else {
      // Change to hamburger icon
      icon.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
      `
      this.toggleTarget.setAttribute('aria-expanded', 'false')
      this.toggleTarget.setAttribute('aria-label', 'Open navigation menu')
    }
  }

  // Handle clicks outside menu
  clickOutside(event) {
    if (!this.isOpen) return
    
    if (this.hasMenuTarget && !this.menuTarget.contains(event.target) && 
        this.hasToggleTarget && !this.toggleTarget.contains(event.target)) {
      this.close()
    }
  }

  // Handle keyboard events
  handleKeyDown(event) {
    if (!this.isOpen) return
    
    switch(event.key) {
      case 'Escape':
        event.preventDefault()
        this.close()
        break
      case 'Tab':
        this.handleTabKey(event)
        break
    }
  }

  // Handle tab key for focus trapping
  handleTabKey(event) {
    if (!this.hasMenuTarget) return
    
    const focusableElements = this.getFocusableElements()
    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]
    
    if (event.shiftKey) {
      // Shift + Tab
      if (document.activeElement === firstElement) {
        event.preventDefault()
        lastElement.focus()
      }
    } else {
      // Tab
      if (document.activeElement === lastElement) {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }

  // Get focusable elements within the menu
  getFocusableElements() {
    if (!this.hasMenuTarget) return []
    
    const selector = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    const elements = Array.from(this.menuTarget.querySelectorAll(selector))
    
    return elements.filter(element => {
      return !element.disabled && 
             !element.getAttribute('aria-hidden') && 
             element.offsetWidth > 0 && 
             element.offsetHeight > 0
    })
  }

  // Trap focus within the menu
  trapFocus() {
    const focusableElements = this.getFocusableElements()
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    }
  }

  // Handle window resize
  handleResize() {
    this.checkScreenSize()
  }

  // Check screen size and auto-close on large screens
  checkScreenSize() {
    const isLargeScreen = window.innerWidth >= 1024 // lg breakpoint
    
    if (isLargeScreen && this.isOpen) {
      this.close()
    }
  }

  // Close menu when navigation link is clicked
  navigateAndClose(event) {
    // Let the link navigate normally, then close the menu
    setTimeout(() => {
      this.close()
    }, 100)
  }
}