// frozen_string_literal: true

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "parametersSection",
    "plaintiffMin",
    "plaintiffIdeal",
    "defendantMax",
    "defendantIdeal",
    "settlementRange",
    "plaintiffMinDisplay",
    "defendantMaxDisplay",
    "useCaseDefaults",
    "useRandomizedDefaults"
  ]

  connect() {
    this.updateParameterOption()
    this.updateSettlementRange()
  }

  updateParameterOption() {
    const selectedOption = this.element.querySelector('input[name="simulation[parameter_option]"]:checked')?.value

    switch (selectedOption) {
      case 'case_defaults':
        this.applyCaseDefaults()
        this.setFieldsReadonly(true)
        this.useCaseDefaultsTarget.value = "true"
        this.useRandomizedDefaultsTarget.value = "false"
        break
      case 'randomized':
        this.applyRandomizedDefaults()
        this.setFieldsReadonly(true)
        this.useCaseDefaultsTarget.value = "false"
        this.useRandomizedDefaultsTarget.value = "true"
        break
      case 'manual':
        this.setFieldsReadonly(false)
        this.useCaseDefaultsTarget.value = "false"
        this.useRandomizedDefaultsTarget.value = "false"
        break
    }

    this.updateSettlementRange()
  }

  applyCaseDefaults() {
    // Get defaults from the global caseDefaults object set in the view
    const caseType = this.element.dataset.caseType
    const defaults = window.caseDefaults?.[caseType] || window.caseDefaults?.default

    if (defaults) {
      this.plaintiffMinTarget.value = defaults.plaintiff_min_acceptable
      this.plaintiffIdealTarget.value = defaults.plaintiff_ideal
      this.defendantMaxTarget.value = defaults.defendant_max_acceptable
      this.defendantIdealTarget.value = defaults.defendant_ideal
    }
  }

  applyRandomizedDefaults() {
    // Generate randomized parameters based on case type
    const caseType = this.element.dataset.caseType
    const baseDefaults = window.caseDefaults?.[caseType] || window.caseDefaults?.default

    if (baseDefaults) {
      const variation = this.getVariationFactor(caseType)

      const plaintiffIdeal = this.randomizeAmount(baseDefaults.plaintiff_ideal, variation)
      const plaintiffMin = this.randomizeAmount(baseDefaults.plaintiff_min_acceptable, variation)
      const defendantMax = this.randomizeAmount(baseDefaults.defendant_max_acceptable, variation)
      const defendantIdeal = this.randomizeAmount(baseDefaults.defendant_ideal, variation)

      // Ensure mathematical validity
      const validParams = this.ensureValidity({
        plaintiff_min_acceptable: plaintiffMin,
        plaintiff_ideal: plaintiffIdeal,
        defendant_max_acceptable: defendantMax,
        defendant_ideal: defendantIdeal
      })

      this.plaintiffMinTarget.value = validParams.plaintiff_min_acceptable
      this.plaintiffIdealTarget.value = validParams.plaintiff_ideal
      this.defendantMaxTarget.value = validParams.defendant_max_acceptable
      this.defendantIdealTarget.value = validParams.defendant_ideal
    }
  }

  getVariationFactor(caseType) {
    switch (caseType) {
      case 'intellectual_property':
        return 0.5
      case 'discrimination':
      case 'sexual_harassment':
        return 0.3
      case 'contract_dispute':
      case 'wrongful_termination':
        return 0.4
      default:
        return 0.3
    }
  }

  randomizeAmount(baseAmount, variationFactor) {
    const minVariation = 1.0 - variationFactor
    const maxVariation = 1.0 + variationFactor
    const variation = minVariation + Math.random() * (maxVariation - minVariation)
    return Math.round(baseAmount * variation)
  }

  ensureValidity(params) {
    // Ensure plaintiff_min <= plaintiff_ideal
    if (params.plaintiff_min_acceptable > params.plaintiff_ideal) {
      params.plaintiff_min_acceptable = Math.round(params.plaintiff_ideal * 0.8)
    }

    // Ensure defendant_ideal <= defendant_max
    if (params.defendant_ideal > params.defendant_max_acceptable) {
      params.defendant_ideal = Math.round(params.defendant_max_acceptable * 0.5)
    }

    // Ensure settlement is possible: plaintiff_min <= defendant_max
    if (params.plaintiff_min_acceptable > params.defendant_max_acceptable) {
      const overlapPoint = (params.plaintiff_min_acceptable + params.defendant_max_acceptable) / 2
      params.plaintiff_min_acceptable = overlapPoint - 10000
      params.defendant_max_acceptable = overlapPoint + 10000
    }

    return params
  }

  setFieldsReadonly(readonly) {
    this.plaintiffMinTarget.readOnly = readonly
    this.plaintiffIdealTarget.readOnly = readonly
    this.defendantMaxTarget.readOnly = readonly
    this.defendantIdealTarget.readOnly = readonly

    // Update visual styling
    const fields = [this.plaintiffMinTarget, this.plaintiffIdealTarget, this.defendantMaxTarget, this.defendantIdealTarget]
    fields.forEach(field => {
      if (readonly) {
        field.classList.add('bg-gray-100', 'cursor-not-allowed')
        field.classList.remove('bg-white')
      } else {
        field.classList.remove('bg-gray-100', 'cursor-not-allowed')
        field.classList.add('bg-white')
      }
    })
  }

  updateSettlementRange() {
    const plaintiffMin = parseInt(this.plaintiffMinTarget.value) || 150000
    const defendantMax = parseInt(this.defendantMaxTarget.value) || 250000

    const formatter = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      maximumFractionDigits: 0
    })

    this.plaintiffMinDisplayTarget.textContent = formatter.format(plaintiffMin)
    this.defendantMaxDisplayTarget.textContent = formatter.format(defendantMax)

    // Update range styling based on validity
    if (plaintiffMin > defendantMax) {
      this.settlementRangeTarget.classList.remove('bg-yellow-50')
      this.settlementRangeTarget.classList.add('bg-red-50')
      this.settlementRangeTarget.querySelector('h4').classList.remove('text-yellow-800')
      this.settlementRangeTarget.querySelector('h4').classList.add('text-red-800')
      this.settlementRangeTarget.querySelector('p').classList.remove('text-yellow-700')
      this.settlementRangeTarget.querySelector('p').classList.add('text-red-700')
      this.settlementRangeTarget.querySelector('p').innerHTML =
        `⚠️ No settlement possible: plaintiff minimum (${formatter.format(plaintiffMin)}) exceeds defendant maximum (${formatter.format(defendantMax)})`
    } else {
      this.settlementRangeTarget.classList.remove('bg-red-50')
      this.settlementRangeTarget.classList.add('bg-yellow-50')
      this.settlementRangeTarget.querySelector('h4').classList.remove('text-red-800')
      this.settlementRangeTarget.querySelector('h4').classList.add('text-yellow-800')
      this.settlementRangeTarget.querySelector('p').classList.remove('text-red-700')
      this.settlementRangeTarget.querySelector('p').classList.add('text-yellow-700')
      this.settlementRangeTarget.querySelector('p').innerHTML =
        `Ensure there's overlap between plaintiff minimum (${formatter.format(plaintiffMin)}) and defendant maximum (${formatter.format(defendantMax)}) for successful negotiations.`
    }
  }
}
