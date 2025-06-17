import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { userId: Number }
  static targets = ["totalScore", "collaborationScore", "notificationArea", "notificationText"]

  connect() {
    this.initializeRealTimeUpdates()
    this.loadPerformanceData()
  }

  disconnect() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }
  }

  // Tab switching functionality
  switchTab(event) {
    event.preventDefault()
    
    const targetTab = event.currentTarget.dataset.tab
    
    // Update tab buttons
    this.element.querySelectorAll('.tab-button').forEach(button => {
      button.classList.remove('active', 'border-blue-500', 'text-blue-600')
      button.classList.add('border-transparent', 'text-gray-500')
    })
    
    event.currentTarget.classList.add('active', 'border-blue-500', 'text-blue-600')
    event.currentTarget.classList.remove('border-transparent', 'text-gray-500')
    
    // Update tab content
    this.element.querySelectorAll('.tab-pane').forEach(pane => {
      pane.style.display = 'none'
      pane.classList.remove('active')
    })
    
    const targetPane = this.element.querySelector(`[data-tab-content="${targetTab}"]`)
    if (targetPane) {
      targetPane.style.display = 'block'
      targetPane.classList.add('active')
      
      // Load tab-specific data
      this.loadTabData(targetTab)
    }
  }

  // Real-time updates using polling (could be upgraded to WebSockets)
  initializeRealTimeUpdates() {
    // Poll for updates every 30 seconds
    this.pollingInterval = setInterval(() => {
      this.checkForScoreUpdates()
    }, 30000)
  }

  async checkForScoreUpdates() {
    try {
      const response = await fetch(`/scoring_dashboard/performance_data.json`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateScoreDisplay(data)
      }
    } catch (error) {
      console.log('Score update check failed:', error)
    }
  }

  updateScoreDisplay(newData) {
    const currentScore = this.getCurrentDisplayedScore()
    
    if (newData.total_score !== currentScore) {
      this.animateScoreChange(newData)
      this.showNotification(`Score updated: +${newData.total_score - currentScore} points`)
    }
  }

  getCurrentDisplayedScore() {
    if (this.hasTotalScoreTarget) {
      const scoreText = this.totalScoreTarget.textContent
      return parseInt(scoreText.split('/')[0])
    }
    return 0
  }

  animateScoreChange(newData) {
    if (this.hasTotalScoreTarget) {
      // Add animation class
      this.totalScoreTarget.classList.add('score-animation')
      
      // Update the score
      this.totalScoreTarget.textContent = `${newData.total_score}/100`
      
      // Remove animation class after animation completes
      setTimeout(() => {
        this.totalScoreTarget.classList.remove('score-animation')
      }, 500)
    }
    
    // Update other score components
    if (this.hasCollaborationScoreTarget && newData.breakdown?.collaboration) {
      this.collaborationScoreTarget.textContent = 
        `${newData.breakdown.collaboration.score}/${newData.breakdown.collaboration.max_points}`
    }
  }

  showNotification(message) {
    if (this.hasNotificationAreaTarget && this.hasNotificationTextTarget) {
      this.notificationTextTarget.textContent = message
      this.notificationAreaTarget.style.display = 'block'
      
      // Auto-hide after 5 seconds
      setTimeout(() => {
        this.notificationAreaTarget.style.display = 'none'
      }, 5000)
    }
  }

  async loadPerformanceData() {
    try {
      const response = await fetch(`/scoring_dashboard/performance_data.json?include_team=true`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateAllScoreDisplays(data)
      }
    } catch (error) {
      console.log('Failed to load performance data:', error)
    }
  }

  updateAllScoreDisplays(data) {
    // Update main score display
    if (this.hasTotalScoreTarget) {
      this.totalScoreTarget.textContent = `${data.total_score}/100`
    }
    
    // Update grade display
    const gradeElement = this.element.querySelector('.performance-grade')
    if (gradeElement) {
      gradeElement.textContent = `Grade: ${data.grade}`
      
      // Update grade styling
      gradeElement.className = gradeElement.className.replace(/grade-\w+/, `grade-${data.grade.toLowerCase()}`)
    }
    
    // Update rank and percentile
    const rankElement = this.element.querySelector('.rank')
    if (rankElement && data.rank) {
      rankElement.textContent = data.rank
    }
    
    const percentileElement = this.element.querySelector('.percentile')
    if (percentileElement && data.percentile) {
      percentileElement.textContent = `${data.percentile}th`
    }
  }

  async loadTabData(tabName) {
    switch(tabName) {
      case 'trends':
        await this.loadTrendsData()
        break
      case 'analysis':
        await this.loadAnalysisData()
        break
      case 'bonus':
        await this.loadBonusData()
        break
    }
  }

  async loadTrendsData() {
    try {
      const response = await fetch(`/scoring_dashboard/trends.json`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateTrendsDisplay(data)
      }
    } catch (error) {
      console.log('Failed to load trends data:', error)
    }
  }

  updateTrendsDisplay(data) {
    // Update trend chart if Chart.js is available
    if (typeof Chart !== 'undefined') {
      this.updateTrendsChart(data.trend_data)
    }
    
    // Update improvement indicators
    const improvementElement = this.element.querySelector('.performance-insight')
    if (improvementElement && data.improvement_analysis) {
      const analysis = data.improvement_analysis
      let insightText = ''
      
      switch(analysis.overall_trend) {
        case 'improving':
          insightText = `📈 Consistent improvement across all metrics (+${analysis.total_improvement} points)`
          break
        case 'declining':
          insightText = `📉 Performance decline detected (${analysis.total_improvement} points)`
          break
        default:
          insightText = '📊 Performance has remained stable'
      }
      
      improvementElement.textContent = insightText
    }
  }

  updateTrendsChart(trendData) {
    const chartCanvas = this.element.querySelector('#trendsChart')
    if (!chartCanvas || !trendData.length) return
    
    // Destroy existing chart if it exists
    if (this.trendsChart) {
      this.trendsChart.destroy()
    }
    
    const ctx = chartCanvas.getContext('2d')
    
    this.trendsChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: trendData.map(point => point.date),
        datasets: [
          {
            label: 'Total Score',
            data: trendData.map(point => point.total_score),
            borderColor: '#3B82F6',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            tension: 0.4
          },
          {
            label: 'Settlement Quality',
            data: trendData.map(point => point.settlement_quality_score),
            borderColor: '#10B981',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            tension: 0.4
          },
          {
            label: 'Legal Strategy',
            data: trendData.map(point => point.legal_strategy_score),
            borderColor: '#8B5CF6',
            backgroundColor: 'rgba(139, 92, 246, 0.1)',
            tension: 0.4
          },
          {
            label: 'Collaboration',
            data: trendData.map(point => point.collaboration_score),
            borderColor: '#F59E0B',
            backgroundColor: 'rgba(245, 158, 11, 0.1)',
            tension: 0.4
          }
        ]
      },
      options: {
        responsive: true,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            position: 'bottom'
          },
          tooltip: {
            mode: 'index',
            intersect: false
          }
        },
        scales: {
          x: {
            display: true,
            title: {
              display: true,
              text: 'Date'
            }
          },
          y: {
            display: true,
            title: {
              display: true,
              text: 'Score'
            },
            min: 0,
            max: 100
          }
        }
      }
    })
  }

  async loadAnalysisData() {
    // Analysis data is typically static, but we could refresh it
    console.log('Loading analysis data...')
  }

  async loadBonusData() {
    // Bonus data could be refreshed to show new opportunities
    console.log('Loading bonus data...')
  }

  // Export functionality
  async exportReport() {
    try {
      window.open('/scoring_dashboard/export_report.pdf', '_blank')
    } catch (error) {
      console.log('Export failed:', error)
      this.showNotification('Export failed. Please try again.')
    }
  }

  // Accessibility helpers
  announceScoreChange(oldScore, newScore) {
    const announcement = `Score updated from ${oldScore} to ${newScore} points`
    
    // Create a temporary element for screen readers
    const announcer = document.createElement('div')
    announcer.setAttribute('aria-live', 'polite')
    announcer.setAttribute('aria-atomic', 'true')
    announcer.style.position = 'absolute'
    announcer.style.left = '-10000px'
    announcer.textContent = announcement
    
    document.body.appendChild(announcer)
    
    setTimeout(() => {
      document.body.removeChild(announcer)
    }, 1000)
  }

  // Keyboard navigation support
  handleKeydown(event) {
    if (event.key === 'Tab') {
      // Ensure proper tab navigation through score elements
      this.manageFocusOrder(event)
    }
  }

  manageFocusOrder(event) {
    const focusableElements = this.element.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    
    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]
    
    if (event.shiftKey && document.activeElement === firstElement) {
      event.preventDefault()
      lastElement.focus()
    } else if (!event.shiftKey && document.activeElement === lastElement) {
      event.preventDefault()
      firstElement.focus()
    }
  }
}