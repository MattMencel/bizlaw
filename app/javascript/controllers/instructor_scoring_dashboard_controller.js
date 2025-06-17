import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["studentTable", "filterInput"]

  connect() {
    this.sortColumn = 'name'
    this.sortDirection = 'asc'
    this.initializeClassCharts()
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

  // Student filtering functionality
  filterStudents(event) {
    const searchTerm = event.target.value.toLowerCase()
    const rows = this.element.querySelectorAll('.student-score')
    
    rows.forEach(row => {
      const studentName = row.querySelector('td:first-child').textContent.toLowerCase()
      const teamName = row.querySelector('td:nth-child(2)').textContent.toLowerCase()
      
      if (studentName.includes(searchTerm) || teamName.includes(searchTerm)) {
        row.style.display = ''
      } else {
        row.style.display = 'none'
      }
    })
  }

  // Table sorting functionality
  sortTable(event) {
    const column = event.currentTarget.dataset.column
    
    // Toggle sort direction if same column, otherwise default to asc
    if (this.sortColumn === column) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc'
    } else {
      this.sortDirection = 'asc'
      this.sortColumn = column
    }
    
    this.performSort(column, this.sortDirection)
    this.updateSortIndicators(event.currentTarget)
  }

  performSort(column, direction) {
    const tbody = this.element.querySelector('.student-scores tbody')
    const rows = Array.from(tbody.querySelectorAll('tr'))
    
    rows.sort((a, b) => {
      let aValue, bValue
      
      switch(column) {
        case 'name':
          aValue = a.querySelector('td:nth-child(1)').textContent.trim()
          bValue = b.querySelector('td:nth-child(1)').textContent.trim()
          break
        case 'team':
          aValue = a.querySelector('td:nth-child(2)').textContent.trim()
          bValue = b.querySelector('td:nth-child(2)').textContent.trim()
          break
        case 'score':
          aValue = parseInt(a.querySelector('td:nth-child(3) .score-value').textContent.split('/')[0])
          bValue = parseInt(b.querySelector('td:nth-child(3) .score-value').textContent.split('/')[0])
          break
        default:
          return 0
      }
      
      if (column === 'score') {
        return direction === 'asc' ? aValue - bValue : bValue - aValue
      } else {
        const comparison = aValue.localeCompare(bValue)
        return direction === 'asc' ? comparison : -comparison
      }
    })
    
    // Reorder the DOM elements
    rows.forEach(row => tbody.appendChild(row))
  }

  updateSortIndicators(clickedHeader) {
    // Reset all sort indicators
    this.element.querySelectorAll('.sortable svg').forEach(svg => {
      svg.style.opacity = '0.3'
    })
    
    // Highlight the active sort column
    const svg = clickedHeader.querySelector('svg')
    if (svg) {
      svg.style.opacity = '1'
      svg.style.transform = this.sortDirection === 'desc' ? 'rotate(180deg)' : 'rotate(0deg)'
    }
  }

  // Student intervention actions
  messageStudent(event) {
    const userId = event.currentTarget.dataset.userId
    this.openMessageModal(userId)
  }

  scheduleStudent(event) {
    const userId = event.currentTarget.dataset.userId
    this.openSchedulingModal(userId)
  }

  assignMentorRole(event) {
    const userId = event.currentTarget.dataset.userId
    this.confirmMentorAssignment(userId)
  }

  // Bulk actions
  bulkMessage() {
    const selectedStudents = this.getSelectedStudents()
    if (selectedStudents.length === 0) {
      alert('Please select students first')
      return
    }
    this.openBulkMessageModal(selectedStudents)
  }

  scheduleOfficeHours() {
    this.openOfficeHoursModal()
  }

  generateReports() {
    this.openReportGenerationModal()
  }

  // Analytics functionality
  async loadTabData(tabName) {
    switch(tabName) {
      case 'analytics':
        await this.loadAnalyticsData()
        break
      case 'interventions':
        await this.loadInterventionData()
        break
    }
  }

  async loadAnalyticsData() {
    try {
      const response = await fetch('/scoring_dashboard/class_analytics.json', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateAnalyticsDisplay(data)
      }
    } catch (error) {
      console.log('Failed to load analytics data:', error)
    }
  }

  updateAnalyticsDisplay(data) {
    // Update class averages
    Object.keys(data.class_averages).forEach(metric => {
      const element = this.element.querySelector(`[data-metric="${metric.replace('_', '-')}"]`)
      if (element) {
        const scoreElement = element.querySelector('.text-2xl')
        if (scoreElement) {
          scoreElement.textContent = data.class_averages[metric]
        }
      }
    })
    
    // Update distribution chart
    this.updateDistributionChart(data.distribution)
    
    // Update role comparison chart
    this.updateRoleComparisonChart(data.role_comparison)
  }

  updateDistributionChart(distribution) {
    const chartCanvas = this.element.querySelector('#distributionChart')
    if (!chartCanvas || typeof Chart === 'undefined') return
    
    if (this.distributionChart) {
      this.distributionChart.destroy()
    }
    
    const ctx = chartCanvas.getContext('2d')
    
    this.distributionChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: distribution.map(item => item.range),
        datasets: [{
          label: 'Number of Students',
          data: distribution.map(item => item.count),
          backgroundColor: ['#EF4444', '#F97316', '#EAB308', '#22C55E', '#059669'],
          borderColor: ['#DC2626', '#EA580C', '#CA8A04', '#16A34A', '#047857'],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              stepSize: 1
            }
          }
        }
      }
    })
  }

  updateRoleComparisonChart(roleComparison) {
    const chartCanvas = this.element.querySelector('#roleComparisonChart')
    if (!chartCanvas || typeof Chart === 'undefined') return
    
    if (this.roleComparisonChart) {
      this.roleComparisonChart.destroy()
    }
    
    const ctx = chartCanvas.getContext('2d')
    
    this.roleComparisonChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Plaintiff Teams', 'Defendant Teams'],
        datasets: [{
          data: [roleComparison.plaintiff_average, roleComparison.defendant_average],
          backgroundColor: ['#3B82F6', '#8B5CF6'],
          borderWidth: 2
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'bottom'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.label}: ${context.parsed} avg score`
              }
            }
          }
        }
      }
    })
  }

  async loadInterventionData() {
    // Load fresh intervention data
    console.log('Loading intervention data...')
  }

  // Export functionality
  async exportClassData() {
    try {
      const response = await fetch('/scoring_dashboard/class_analytics.json', {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.downloadCSV(data)
      }
    } catch (error) {
      console.log('Export failed:', error)
      alert('Export failed. Please try again.')
    }
  }

  downloadCSV(data) {
    const csvContent = this.convertToCSV(data)
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    
    if (link.download !== undefined) {
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `class_performance_${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    }
  }

  convertToCSV(data) {
    const headers = ['Student Name', 'Team', 'Total Score', 'Grade', 'Settlement Quality', 'Legal Strategy', 'Collaboration', 'Efficiency']
    const rows = []
    
    // Add class averages row
    rows.push([
      'Class Average',
      '-',
      data.class_averages.total_score,
      '-',
      data.class_averages.settlement_quality,
      data.class_averages.legal_strategy,
      data.class_averages.collaboration,
      data.class_averages.efficiency
    ])
    
    return [headers.join(','), ...rows.map(row => row.join(','))].join('\n')
  }

  // Modal functions (simplified - would integrate with actual modal system)
  openMessageModal(userId) {
    console.log(`Opening message modal for user ${userId}`)
    // Implementation would depend on your modal system
  }

  openSchedulingModal(userId) {
    console.log(`Opening scheduling modal for user ${userId}`)
    // Implementation would depend on your modal system
  }

  confirmMentorAssignment(userId) {
    if (confirm('Assign this student as a mentor for struggling peers?')) {
      console.log(`Assigning mentor role to user ${userId}`)
      // Implementation would make API call to assign mentor role
    }
  }

  openBulkMessageModal(studentIds) {
    console.log(`Opening bulk message modal for students: ${studentIds}`)
    // Implementation would depend on your modal system
  }

  openOfficeHoursModal() {
    console.log('Opening office hours scheduling modal')
    // Implementation would depend on your modal system
  }

  openReportGenerationModal() {
    console.log('Opening report generation modal')
    // Implementation would depend on your modal system
  }

  getSelectedStudents() {
    // This would get students selected via checkboxes
    // For now, return students needing help
    const helpRows = this.element.querySelectorAll('.student-score.low-score')
    return Array.from(helpRows).map(row => {
      const userId = row.querySelector('button[data-user-id]')?.dataset.userId
      return userId
    }).filter(Boolean)
  }

  // Chart initialization
  initializeClassCharts() {
    // Charts are initialized by the view template
    // This method could be used for additional chart setup
  }

  // Score adjustment functionality
  async adjustScore(performanceScoreId, adjustment, reason) {
    try {
      const response = await fetch(`/scoring_dashboard/update_score/${performanceScoreId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          performance_score: {
            instructor_adjustment: adjustment,
            adjustment_reason: reason
          }
        })
      })
      
      if (response.ok) {
        const data = await response.json()
        this.showSuccessMessage(`Score updated to ${data.new_total}`)
        this.refreshStudentTable()
      } else {
        const error = await response.json()
        this.showErrorMessage(error.errors)
      }
    } catch (error) {
      console.log('Score adjustment failed:', error)
      this.showErrorMessage('Failed to adjust score. Please try again.')
    }
  }

  showSuccessMessage(message) {
    // Implementation would depend on your notification system
    console.log('Success:', message)
  }

  showErrorMessage(message) {
    // Implementation would depend on your notification system
    console.log('Error:', message)
  }

  refreshStudentTable() {
    // Reload the current page to refresh data
    window.location.reload()
  }
}