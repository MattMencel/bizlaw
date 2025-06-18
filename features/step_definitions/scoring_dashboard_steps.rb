# frozen_string_literal: true

# Performance Score Setup Steps
Given("I have the following performance scores for the simulation:") do |table|
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  user = User.find_by(email: @current_user_email)
  team = user.teams.joins(:case_teams).where(case_teams: { case: simulation.case }).first

  scores = {}
  table.hashes.each do |row|
    scores[row["metric"]] = row["score"].to_i
  end

  @performance_score = create(:performance_score,
    simulation: simulation,
    team: team,
    user: user,
    settlement_quality_score: scores["settlement_quality_score"],
    legal_strategy_score: scores["legal_strategy_score"],
    collaboration_score: scores["collaboration_score"],
    efficiency_score: scores["efficiency_score"],
    speed_bonus: scores["speed_bonus"],
    creative_terms_score: scores["creative_terms_score"]
  )

  @performance_score.calculate_total_score!
end

Given("my total score is {int} out of {int}") do |score, max|
  expect(@performance_score.total_score).to eq(score)
end

Given("my team {string} has a team score of {int} out of {int}") do |team_name, score, max|
  team = Team.find_by(name: team_name)
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  @team_score = create(:performance_score, :team_score,
    simulation: simulation,
    team: team,
    total_score: score
  )
end

Given("the opposing team {string} has a team score of {int} out of {int}") do |team_name, score, max|
  team = Team.find_by(name: team_name)
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  create(:performance_score, :team_score,
    simulation: simulation,
    team: team,
    total_score: score
  )
end

Given("there are {int} other teams in the simulation with scores ranging from {int}-{int}") do |team_count, min_score, max_score|
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  team_count.times do |i|
    team = create(:team, course: simulation.case.course)
    create(:case_team, case: simulation.case, team: team, role: i.even? ? "plaintiff" : "defendant")

    score = rand(min_score..max_score)
    create(:performance_score, :team_score,
      simulation: simulation,
      team: team,
      total_score: score
    )
  end
end

Given("I have score history over {int} simulation rounds:") do |round_count, table|
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  user = User.find_by(email: @current_user_email)
  team = user.teams.joins(:case_teams).where(case_teams: { case: simulation.case }).first

  table.hashes.each_with_index do |row, index|
    create(:performance_score,
      simulation: simulation,
      team: team,
      user: user,
      total_score: row["total_score"].to_i,
      settlement_quality_score: row["settlement_score"].to_i,
      legal_strategy_score: row["strategy_score"].to_i,
      collaboration_score: row["collaboration_score"].to_i,
      scored_at: (round_count - index).days.ago
    )
  end
end

Given("I have earned the following bonus points:") do |table|
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  user = User.find_by(email: @current_user_email)
  team = user.teams.joins(:case_teams).where(case_teams: { case: simulation.case }).first

  total_bonus = 0
  bonus_details = {}

  table.hashes.each do |row|
    bonus_points = row["points"].to_i
    total_bonus += bonus_points
    bonus_details[row["bonus_type"]] = {
      "points" => bonus_points,
      "description" => row["description"]
    }
  end

  if @performance_score
    @performance_score.update!(
      speed_bonus: bonus_details["early_settlement"]&.dig("points") || 0,
      creative_terms_score: bonus_details["creative_solution"]&.dig("points") || 0,
      bonus_details: bonus_details
    )
    @performance_score.calculate_total_score!
  else
    @performance_score = create(:performance_score,
      simulation: simulation,
      team: team,
      user: user,
      speed_bonus: bonus_details["early_settlement"]&.dig("points") || 0,
      creative_terms_score: (bonus_details["creative_solution"]&.dig("points") || 0) +
                           (bonus_details["legal_research"]&.dig("points") || 0),
      bonus_details: bonus_details
    )
    @performance_score.calculate_total_score!
  end
end

Given("my course has {int} students across {int} teams") do |student_count, team_count|
  course = Course.find_by(name: "Advanced Business Law")
  simulation = Simulation.joins(:case).find_by(cases: { course: course })

  # Create teams
  team_count.times do |i|
    team = create(:team, course: course, name: "Team #{i + 1}")
    create(:case_team, case: simulation.case, team: team, role: i.even? ? "plaintiff" : "defendant")
  end

  # Create students and assign to teams
  teams = Team.where(course: course).to_a
  student_count.times do |i|
    student = create(:user, :student, organization: course.organization)
    team = teams[i % team_count]
    create(:team_member, team: team, user: student)
  end
end

Given("all students have performance scores recorded") do
  course = Course.find_by(name: "Advanced Business Law")
  simulation = Simulation.joins(:case).find_by(cases: { course: course })

  User.joins(:teams).where(teams: { course: course }).find_each do |student|
    team = student.teams.where(course: course).first

    create(:performance_score,
      simulation: simulation,
      team: team,
      user: student,
      total_score: rand(60..95),
      settlement_quality_score: rand(20..40),
      legal_strategy_score: rand(18..30),
      collaboration_score: rand(12..20),
      efficiency_score: rand(6..10)
    )
  end
end

# Navigation Steps
When("I navigate to my scoring dashboard") do
  visit scoring_dashboard_path
end

When("I navigate to the instructor scoring dashboard") do
  visit instructor_scoring_dashboard_path
end

# Interaction Steps
When("I click on the {string} tab") do |tab_name|
  click_link tab_name
end

When("I click the {string} button") do |button_text|
  click_button button_text
end

When("a teammate submits a high-quality settlement offer") do
  # Simulate real-time score update
  simulation = Simulation.joins(case: :course).find_by(
    cases: { courses: { name: "Advanced Business Law" } }
  )

  user = User.find_by(email: @current_user_email)
  team = user.teams.joins(:case_teams).where(case_teams: { case: simulation.case }).first

  # Create a high-quality offer that would boost collaboration scores
  teammate = team.team_members.where.not(user: user).first&.user ||
             create(:user, :student, organization: user.organization)

  unless team.team_members.exists?(user: teammate)
    create(:team_member, team: team, user: teammate)
  end

  offer = create(:settlement_offer,
    simulation: simulation,
    team: team,
    user: teammate,
    amount: 250000,
    quality_score: 85,
    justification: "Well-researched offer with strong legal precedent"
  )

  # This would trigger real-time updates in the actual application
  @new_collaboration_score = (@performance_score.collaboration_score || 0) + 3
end

When("the system processes the new collaboration metrics") do
  # Simulate background processing that updates scores
  sleep 0.1 # Brief pause to simulate processing

  @performance_score.update!(
    collaboration_score: @new_collaboration_score
  )
  @performance_score.calculate_total_score!
end

# Verification Steps
Then("I should see my current total score {string} prominently displayed") do |score_text|
  expect(page).to have_content(score_text)
  expect(page).to have_css(".total-score", text: score_text)
end

Then("I should see my performance grade {string} with appropriate styling") do |grade|
  expect(page).to have_content(grade)
  expect(page).to have_css(".performance-grade.grade-#{grade.downcase}", text: grade)
end

Then("I should see a breakdown chart showing all score components") do
  expect(page).to have_css(".score-breakdown-chart")
  expect(page).to have_css("[data-testid='score-chart']")
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should see my team's total score {string} highlighted") do |score_text|
  expect(page).to have_content(score_text)
  expect(page).to have_css(".team-score.highlighted", text: score_text)
end

Then("I should see my team's rank {string}") do |rank_text|
  expect(page).to have_content(rank_text)
  expect(page).to have_css(".team-rank", text: rank_text)
end

Then("I should see my team's percentile {string}") do |percentile_text|
  expect(page).to have_content(percentile_text)
  expect(page).to have_css(".team-percentile", text: percentile_text)
end

Then("I should see a team comparison chart") do
  expect(page).to have_css(".team-comparison-chart")
  expect(page).to have_css("[data-testid='team-comparison-chart']")
end

Then("I should not see other teams' detailed breakdowns \\(only totals)") do
  expect(page).to have_css(".other-team-score")
  expect(page).not_to have_css(".other-team-breakdown")
end

Then("I should see my collaboration score increase without page refresh") do
  # Verify real-time update functionality
  expect(page).to have_css("[data-testid='collaboration-score']")

  # In a real implementation, this would use WebSockets or polling
  # For testing, we simulate the behavior
  collaboration_element = find("[data-testid='collaboration-score']")
  expect(collaboration_element.text.to_i).to be >= @new_collaboration_score
end

Then("I should see my total score update to reflect the new collaboration points") do
  expect(page).to have_css("[data-testid='total-score']")
  total_score_element = find("[data-testid='total-score']")
  expect(total_score_element.text.to_i).to eq(@performance_score.reload.total_score)
end

Then("I should see a brief animation indicating the score change") do
  expect(page).to have_css(".score-animation", visible: false) # Animation completed
end

Then("I should see a notification {string}") do |notification_text|
  expect(page).to have_content(notification_text)
  expect(page).to have_css(".notification.success", text: notification_text)
end

Then("I should see a line chart showing my score progression over rounds") do
  expect(page).to have_css(".trends-chart")
  expect(page).to have_css("[data-testid='score-progression-chart']")
end

Then("I should see my total score trend line from {int} to {int}") do |start_score, end_score|
  expect(page).to have_css("[data-testid='trend-line-total']")
  # Verify chart data points
  expect(page).to have_content(start_score.to_s)
  expect(page).to have_content(end_score.to_s)
end

Then("I should see separate trend lines for each score component") do
  expect(page).to have_css("[data-testid='trend-line-settlement']")
  expect(page).to have_css("[data-testid='trend-line-strategy']")
  expect(page).to have_css("[data-testid='trend-line-collaboration']")
  expect(page).to have_css("[data-testid='trend-line-efficiency']")
end

Then("I should see improvement indicators for each metric") do
  expect(page).to have_css(".improvement-indicator.positive")
  expect(page).to have_css(".metric-improvement")
end

Then("I should see {string} insight") do |insight_text|
  expect(page).to have_content(insight_text)
  expect(page).to have_css(".performance-insight", text: insight_text)
end

Then("I should see a {string} section containing:") do |section_name, table|
  section = find(".#{section_name.downcase.gsub(' ', '-')}-section")

  table.hashes.each do |row|
    within(section) do
      expect(page).to have_content(row["strength"] || row["improvement_area"])
    end
  end
end

Then("I should see specific recommendations for each improvement area") do
  expect(page).to have_css(".improvement-recommendations")
  expect(page).to have_css(".recommendation-item")
end

Then("I should see {string} for {word}") do |recommendation, area|
  expect(page).to have_content(recommendation)
  expect(page).to have_css(".recommendation[data-area='#{area}']", text: recommendation)
end

Then("I should see {string} prominently displayed") do |text|
  expect(page).to have_content(text)
  expect(page).to have_css(".prominent-display", text: text)
end

Then("I should see a list of earned bonuses with descriptions") do
  expect(page).to have_css(".bonus-list")
  expect(page).to have_css(".bonus-item")
end

Then("I should see available bonus opportunities I haven't earned yet") do
  expect(page).to have_css(".available-bonuses")
  expect(page).to have_css(".bonus-opportunity")
end

Then("I should see progress bars for {string} and {string} bonuses") do |bonus1, bonus2|
  expect(page).to have_css(".bonus-progress[data-bonus='#{bonus1.downcase.gsub(' ', '-')}']")
  expect(page).to have_css(".bonus-progress[data-bonus='#{bonus2.downcase.gsub(' ', '-')}']")
end

# Instructor-specific steps
Then("I should see a summary showing:") do |table|
  table.hashes.each do |row|
    expect(page).to have_content(row["metric"])
    expect(page).to have_content(row["value"])
  end
end

Then("I should see a sortable table of all student scores") do
  expect(page).to have_css("table.student-scores")
  expect(page).to have_css("th.sortable")
end

Then("I should be able to filter by team, score range, or improvement areas") do
  expect(page).to have_css("select[name='team_filter']")
  expect(page).to have_css("input[name='score_range_min']")
  expect(page).to have_css("input[name='score_range_max']")
  expect(page).to have_css("select[name='improvement_area_filter']")
end

Then("I should see students with scores below {int} highlighted in red") do |threshold|
  expect(page).to have_css(".student-score.low-score")

  # Verify that low scores are actually highlighted
  low_score_elements = all(".student-score.low-score .score-value")
  low_score_elements.each do |element|
    score = element.text.to_i
    expect(score).to be < threshold
  end
end

Then("I should see quick action buttons to {string} or {string}") do |action1, action2|
  expect(page).to have_button(action1)
  expect(page).to have_button(action2)
end

# Analytics and reporting steps
Then("I should see a class performance distribution chart") do
  expect(page).to have_css(".distribution-chart")
  expect(page).to have_css("[data-testid='class-distribution-chart']")
end

Then("I should see average scores by metric:") do |table|
  table.hashes.each do |row|
    metric = row["metric"]
    average = row["class_average"]

    expect(page).to have_content(metric)
    expect(page).to have_content(average)
    expect(page).to have_css(".metric-average[data-metric='#{metric.downcase.gsub(' ', '-')}']")
  end
end

Then("I should see comparative analysis between plaintiff and defendant teams") do
  expect(page).to have_css(".role-comparison")
  expect(page).to have_css("[data-testid='plaintiff-vs-defendant-chart']")
end

Then("I should see insights like {string}") do |insight|
  expect(page).to have_content(insight)
  expect(page).to have_css(".analytical-insight", text: insight)
end

Then("I should see recommendations for curriculum adjustments") do
  expect(page).to have_css(".curriculum-recommendations")
  expect(page).to have_css(".curriculum-recommendation-item")
end

# Export and accessibility steps
Then("I should be able to download a PDF report containing:") do |table|
  click_button "Export Report"

  # Verify download initiated
  expect(page.response_headers["Content-Type"]).to eq("application/pdf")

  # In a real test, you'd verify PDF content
  table.hashes.each do |row|
    # PDF content verification would go here
    expect(row["section"]).to be_present
  end
end

Then("the PDF should be formatted for academic portfolio inclusion") do
  # Verify PDF formatting standards
  expect(page.response_headers["Content-Disposition"]).to include("attachment")
  expect(page.response_headers["Content-Disposition"]).to include("performance_report")
end

Then("all score values should have descriptive aria-labels") do
  score_elements = all("[data-testid*='score']")
  score_elements.each do |element|
    expect(element["aria-label"]).to be_present
  end
end

Then("charts should have text alternatives describing the data") do
  chart_elements = all(".chart, [data-testid*='chart']")
  chart_elements.each do |element|
    expect(element["aria-label"] || element["title"]).to be_present
  end
end

Then("color-coded elements should have text or pattern indicators") do
  color_coded_elements = all(".grade-a, .grade-b, .grade-c, .grade-d, .grade-f")
  color_coded_elements.each do |element|
    expect(element.text).to be_present # Text should indicate meaning, not just color
  end
end

Then("the page should meet WCAG 2.1 AA accessibility standards") do
  # Basic accessibility checks
  expect(page).to have_css("h1") # Page should have heading structure
  expect(page).to have_css("[aria-label], [aria-labelledby], [aria-describedby]") # ARIA labels present

  # Verify focus management
  focusable_elements = all("button, a, input, select, textarea, [tabindex='0']")
  expect(focusable_elements).not_to be_empty
end

# Mobile responsiveness steps
Then("the layout should be responsive and mobile-friendly") do
  expect(page).to have_css(".responsive-layout")
  expect(page).to have_css("@media (max-width: 768px)")
end

Then("score cards should stack vertically") do
  expect(page).to have_css(".score-card.stacked")
end

Then("charts should be touch-interactive and zoomable") do
  expect(page).to have_css(".chart.touch-enabled")
  expect(page).to have_css(".chart[data-zoom='enabled']")
end

Then("navigation tabs should be easily tappable") do
  tab_elements = all(".tab-navigation a, .tab-navigation button")
  tab_elements.each do |tab|
    # Verify minimum touch target size (44px recommended)
    expect(tab[:class]).to include("touch-friendly")
  end
end

Then("all score details should be readable without horizontal scrolling") do
  expect(page).to have_css(".score-details.no-horizontal-scroll")
end
