# Test Coverage Roadmap: 57% → 80%

## Executive Summary

**Current Coverage:** 57.22% (2,918 / 5,100 lines)  
**Target Coverage:** 80%  
**Gap to Close:** 22.78 percentage points  
**Additional Lines Needed:** ~1,165 lines of tested code  
**Estimated Timeline:** 4-7 weeks  
**Estimated Impact:** From current 57% to 85%+ coverage

## High-Impact Priority Files

### 🔥 Tier 1: Critical Controllers (Estimated +15% coverage)

#### 1. `app/controllers/negotiations_controller.rb` - **HIGHEST PRIORITY**
- **Lines:** 602 (largest untested file)
- **Estimated Impact:** +11.8% coverage
- **Complexity:** Very High - Core negotiation logic, settlement offers, client consultation
- **Current Coverage:** 0%
- **Priority:** CRITICAL - This is the heart of the application
- **Testing Strategy:**
  - Start with happy path: `index`, `submit_offer`, `counter_offer`
  - Mock AI services and external dependencies
  - Test authorization and user permissions
  - Cover edge cases: invalid offers, API failures, timeout scenarios
  - Integration tests for settlement workflows

#### 2. `app/controllers/cases_controller.rb`
- **Lines:** 132
- **Estimated Impact:** +2.6% coverage
- **Complexity:** Medium - CRUD operations with complex associations
- **Testing Strategy:** Standard controller tests, authorization, nested resources

#### 3. `app/controllers/courses_controller.rb`
- **Lines:** 184
- **Estimated Impact:** +3.6% coverage
- **Complexity:** Medium - Course management with student assignments
- **Testing Strategy:** Focus on invitation flows and student enrollment

#### 4. `app/controllers/teams_controller.rb`
- **Lines:** 98
- **Estimated Impact:** +1.9% coverage
- **Complexity:** Medium - Team management with member associations
- **Testing Strategy:** CRUD operations plus team member management

### 🎯 Tier 2: Critical Services (Estimated +12% coverage)

#### 5. `app/services/case_scenario_service.rb`
- **Lines:** 377
- **Estimated Impact:** +7.4% coverage
- **Complexity:** Very High - Complex case simulation and scenario generation
- **Current Coverage:** 0%
- **Testing Strategy:**
  - Mock external scenario data sources
  - Test scenario generation algorithms
  - Validate case setup and configuration
  - Integration tests with simulation models

#### 6. `app/services/simulation_orchestration_service.rb`
- **Lines:** 335
- **Estimated Impact:** +6.6% coverage
- **Complexity:** Very High - Orchestrates entire simulation lifecycle
- **Testing Strategy:**
  - Service integration tests
  - Mock dependent services
  - Test state transitions and workflow management
  - Error handling and rollback scenarios

#### 7. `app/services/performance_calculator.rb`
- **Lines:** ~150 (estimated)
- **Estimated Impact:** +2.9% coverage
- **Complexity:** Medium - Performance scoring and calculations
- **Testing Strategy:** Unit tests with various calculation scenarios

### 📊 Tier 3: Critical Models (Estimated +8% coverage)

#### 8. `app/models/arbitration_outcome.rb`
- **Lines:** 348
- **Estimated Impact:** +6.8% coverage
- **Complexity:** High - Complex arbitration logic and calculations
- **Current Coverage:** 0%
- **Testing Strategy:**
  - Validation rules and constraints
  - State transition logic
  - Calculation methods
  - Association behaviors

#### 9. `app/models/client_feedback.rb`
- **Lines:** 258
- **Estimated Impact:** +5.1% coverage
- **Complexity:** Medium - AI integration and feedback processing
- **Testing Strategy:**
  - Model validations and associations
  - AI service integration points
  - Feedback categorization logic

#### 10. `app/models/simulation_event.rb`
- **Lines:** 204
- **Estimated Impact:** +4.0% coverage
- **Complexity:** Medium - Event tracking and state management
- **Testing Strategy:** Event creation, validation, and querying

### 🔧 Tier 4: Supporting Files (Estimated +5% coverage)

#### 11. Admin Controllers (Multiple files)
- **Combined Lines:** ~400
- **Estimated Impact:** +7.8% coverage
- **Files:**
  - `app/controllers/admin/dashboard_controller.rb`
  - `app/controllers/admin/licenses_controller.rb`
  - `app/controllers/admin/organizations_controller.rb` 
  - `app/controllers/admin/users_controller.rb`
- **Testing Strategy:** Focus on authorization and admin-specific functionality

#### 12. Additional Models
- `app/models/ai_usage_alert.rb` (69 lines) - +1.4% coverage
- `app/models/ai_usage_log.rb` (63 lines) - +1.2% coverage
- `app/models/personality_consistency_tracker.rb` (39 lines) - +0.8% coverage

## Implementation Phases

### 📈 Phase 1: Quick Wins (Target: 72% coverage, 1-2 weeks)
**Focus:** High-impact, medium-complexity files

1. **Week 1:**
   - `app/controllers/cases_controller.rb` (+2.6%)
   - `app/controllers/teams_controller.rb` (+1.9%)
   - `app/controllers/courses_controller.rb` (+3.6%)
   - `app/models/client_feedback.rb` (+5.1%)

2. **Week 2:**
   - `app/models/simulation_event.rb` (+4.0%)
   - Basic admin controllers (+3.0%)

**Expected Coverage:** ~72%

### 🚀 Phase 2: Core Business Logic (Target: 82% coverage, 2-3 weeks)
**Focus:** Complex controllers and services

3. **Week 3-4:**
   - `app/controllers/negotiations_controller.rb` (+11.8%) - **CRITICAL**
   - Start with basic actions, expand to complex flows

4. **Week 5:**
   - `app/services/case_scenario_service.rb` (+7.4%)
   - `app/models/arbitration_outcome.rb` (+6.8%)

**Expected Coverage:** ~82%

### 🎯 Phase 3: Advanced Features (Target: 87% coverage, 1-2 weeks)
**Focus:** Complex services and remaining gaps

5. **Week 6-7:**
   - `app/services/simulation_orchestration_service.rb` (+6.6%)
   - `app/services/performance_calculator.rb` (+2.9%)
   - Remaining admin controllers and AI models (+3.0%)

**Expected Coverage:** ~87%

## Testing Strategy Guidelines

### Controller Testing Approach
```ruby
# Focus on request specs rather than controller specs
describe "POST /negotiations/submit_offer" do
  it "creates settlement offer with valid params" do
    post negotiations_submit_offer_path(simulation), params: valid_params
    expect(response).to have_http_status(:success)
    expect(SettlementOffer.count).to eq(1)
  end
end
```

### Service Testing Approach
```ruby
# Mock external dependencies, test business logic
describe CaseScenarioService do
  let(:service) { described_class.new(simulation) }
  
  before do
    allow(ExternalScenarioAPI).to receive(:fetch).and_return(mock_data)
  end
  
  it "generates valid scenario configuration" do
    result = service.generate_scenario
    expect(result).to be_valid
    expect(result.plaintiff_info).to be_present
  end
end
```

### Model Testing Focus
```ruby
# Test validations, associations, and business methods
describe ArbitrationOutcome do
  it "calculates damages correctly" do
    outcome = build(:arbitration_outcome, base_amount: 100_000)
    expect(outcome.total_damages).to eq(expected_amount)
  end
end
```

## Dependencies and Prerequisites

### Required Mocking/Stubbing
- **AI Services:** GoogleAI, PersonalityService
- **External APIs:** Any third-party integrations
- **Email Services:** ActionMailer deliveries
- **File Storage:** Document attachments
- **Background Jobs:** Simulation processing

### Factory Bot Requirements
- Ensure comprehensive factories exist for all models
- Add traits for different states and scenarios
- Mock complex associations appropriately

### Test Database Setup
- Seed data for scenarios and case types
- Mock external service responses
- Ensure proper test isolation

## Success Metrics

### Coverage Targets by Phase
- **Phase 1:** 72% coverage (+15% from current)
- **Phase 2:** 82% coverage (+25% from current) 
- **Phase 3:** 87% coverage (+30% from current)

### Quality Metrics
- **Test Reliability:** All tests pass consistently
- **Performance:** Test suite runs in under 5 minutes
- **Maintainability:** Clear, readable test descriptions
- **Edge Cases:** Critical error paths covered

## Risk Mitigation

### High-Risk Areas
1. **Complex AI Integrations** - Extensive mocking required
2. **Async Processing** - Background job testing complexity
3. **Complex Business Logic** - Intricate scenario generation
4. **External Dependencies** - Third-party service reliability

### Mitigation Strategies
- Start with happy paths, expand to edge cases
- Use VCR for API interactions if needed
- Mock complex dependencies extensively
- Focus on business logic over implementation details
- Parallelize test development across multiple developers

## Resource Requirements

### Development Time
- **Junior Developer:** 8-10 weeks
- **Mid-Level Developer:** 6-7 weeks  
- **Senior Developer:** 4-5 weeks
- **Team of 2-3 Developers:** 2-3 weeks

### Tools and Infrastructure
- Existing RSpec + FactoryBot setup ✅
- SimpleCov for coverage reporting ✅
- CI/CD pipeline integration needed
- Test database optimization recommended

---

**Next Steps:**
1. Review and approve this roadmap
2. Assign development resources
3. Start with Phase 1 quick wins
4. Establish coverage monitoring in CI/CD
5. Track progress weekly against targets

**Success Criteria:**
- Achieve 80%+ test coverage
- Maintain or improve test suite performance
- Ensure critical business logic is thoroughly tested
- Establish sustainable testing practices for future development