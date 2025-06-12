import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["termSelect", "startDate", "endDate"]

  connect() {
    // Load term data from the JSON script tag
    const dataScript = document.querySelector('[data-term-dates-data]')
    if (dataScript) {
      try {
        this.termData = JSON.parse(dataScript.textContent)
      } catch (e) {
        console.error('Failed to parse term dates data:', e)
        this.termData = {}
      }
    } else {
      this.termData = {}
    }
  }

  updateDates() {
    const selectedTermId = this.termSelectTarget.value

    if (selectedTermId && this.termData[selectedTermId]) {
      const termInfo = this.termData[selectedTermId]

      // Update the date fields with term dates
      if (termInfo.start_date) {
        this.startDateTarget.value = termInfo.start_date
      }

      if (termInfo.end_date) {
        this.endDateTarget.value = termInfo.end_date
      }

      // Add visual feedback to show dates were auto-filled
      this.addAutoFillFeedback()
    } else {
      // Clear dates if no term selected
      this.startDateTarget.value = ''
      this.endDateTarget.value = ''
      this.removeAutoFillFeedback()
    }
  }

  addAutoFillFeedback() {
    [this.startDateTarget, this.endDateTarget].forEach(field => {
      field.classList.add('bg-blue-50', 'border-blue-300')

      // Remove the highlight after a short delay
      setTimeout(() => {
        field.classList.remove('bg-blue-50', 'border-blue-300')
      }, 2000)
    })
  }

  removeAutoFillFeedback() {
    [this.startDateTarget, this.endDateTarget].forEach(field => {
      field.classList.remove('bg-blue-50', 'border-blue-300')
    })
  }
}
