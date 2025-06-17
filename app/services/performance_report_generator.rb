# frozen_string_literal: true

require 'prawn'
require 'prawn/table'

class PerformanceReportGenerator
  attr_reader :user, :options

  def initialize(user:, include_trends: false, include_recommendations: false)
    @user = user
    @options = {
      include_trends: include_trends,
      include_recommendations: include_recommendations
    }
  end

  def generate_pdf
    Prawn::Document.new do |pdf|
      add_header(pdf)
      add_performance_summary(pdf)
      add_score_breakdown(pdf)
      add_trends_section(pdf) if options[:include_trends]
      add_recommendations_section(pdf) if options[:include_recommendations]
      add_footer(pdf)
    end.render
  end

  private

  def current_simulation
    @current_simulation ||= user.teams
                               .joins(case_teams: { case: :simulation })
                               .merge(Simulation.active)
                               .first&.case&.simulation
  end

  def current_performance_score
    @current_performance_score ||= begin
      return nil unless current_simulation
      
      user_team = user.teams.joins(:case_teams)
                           .where(case_teams: { case: current_simulation.case })
                           .first
      
      PerformanceScore.find_by(
        simulation: current_simulation,
        team: user_team,
        user: user,
        score_type: "individual"
      )
    end
  end

  def add_header(pdf)
    pdf.font "Helvetica", size: 20, style: :bold
    pdf.text "Performance Report", align: :center
    
    pdf.move_down 10
    pdf.font "Helvetica", size: 14
    pdf.text "Student: #{user.full_name}", align: :center
    pdf.text "Generated: #{Date.current.strftime('%B %d, %Y')}", align: :center
    
    if current_simulation
      pdf.text "Simulation: #{current_simulation.case.title}", align: :center
    end
    
    pdf.move_down 20
    pdf.stroke_horizontal_rule
    pdf.move_down 20
  end

  def add_performance_summary(pdf)
    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Performance Summary"
    pdf.move_down 10

    if current_performance_score
      summary_data = [
        ["Total Score", "#{current_performance_score.total_score}/100"],
        ["Grade", current_performance_score.performance_grade],
        ["Class Rank", "#{current_performance_score.rank_in_simulation}"],
        ["Percentile", "#{current_performance_score.percentile_in_simulation}th"],
        ["Last Updated", current_performance_score.scored_at.strftime('%B %d, %Y')]
      ]

      pdf.table(summary_data, 
        header: false,
        cell_style: { 
          borders: [:top, :bottom], 
          padding: [8, 12],
          size: 12
        },
        column_widths: [200, 200]
      )
    else
      pdf.font "Helvetica", size: 12
      pdf.text "No performance data available for active simulations."
    end

    pdf.move_down 20
  end

  def add_score_breakdown(pdf)
    return unless current_performance_score

    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Score Breakdown"
    pdf.move_down 10

    breakdown_data = [
      ["Component", "Score", "Max Points", "Percentage", "Weight"]
    ]

    current_performance_score.score_breakdown.each do |component, details|
      percentage = details["max_points"] > 0 ? 
        ((details["score"].to_f / details["max_points"]) * 100).round(1) : 0
      
      breakdown_data << [
        component.humanize,
        details["score"].to_s,
        details["max_points"].to_s,
        "#{percentage}%",
        details["weight"]
      ]
    end

    pdf.table(breakdown_data,
      header: true,
      cell_style: { 
        borders: [:top, :bottom],
        padding: [6, 8],
        size: 10
      },
      header_color: "E8E8E8"
    )

    pdf.move_down 20
  end

  def add_trends_section(pdf)
    return unless current_simulation

    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Performance Trends"
    pdf.move_down 10

    user_team = user.teams.joins(:case_teams)
                         .where(case_teams: { case: current_simulation.case })
                         .first

    trend_scores = PerformanceScore.where(
      simulation: current_simulation,
      team: user_team,
      user: user
    ).order(:scored_at).limit(10)

    if trend_scores.any?
      trend_data = [["Date", "Total Score", "Settlement", "Strategy", "Collaboration"]]
      
      trend_scores.each do |score|
        trend_data << [
          score.scored_at.strftime('%m/%d/%Y'),
          score.total_score.to_s,
          (score.settlement_quality_score || 0).to_s,
          (score.legal_strategy_score || 0).to_s,
          (score.collaboration_score || 0).to_s
        ]
      end

      pdf.table(trend_data,
        header: true,
        cell_style: { 
          borders: [:top, :bottom],
          padding: [6, 8],
          size: 9
        },
        header_color: "E8E8E8"
      )

      # Add trend analysis
      if trend_scores.count >= 2
        first_score = trend_scores.first.total_score
        last_score = trend_scores.last.total_score
        improvement = last_score - first_score

        pdf.move_down 10
        pdf.font "Helvetica", size: 12
        
        trend_text = if improvement > 5
                      "📈 Your performance shows consistent improvement (+#{improvement} points)"
                    elsif improvement < -5
                      "📉 Your performance shows a decline (#{improvement} points)"
                    else
                      "📊 Your performance has remained stable"
                    end
        
        pdf.text trend_text
      end
    else
      pdf.font "Helvetica", size: 12
      pdf.text "Insufficient data for trend analysis."
    end

    pdf.move_down 20
  end

  def add_recommendations_section(pdf)
    return unless current_performance_score

    pdf.font "Helvetica", size: 16, style: :bold
    pdf.text "Recommendations for Improvement"
    pdf.move_down 10

    strengths = current_performance_score.identify_strengths
    improvement_areas = current_performance_score.identify_improvement_areas

    if strengths.any?
      pdf.font "Helvetica", size: 14, style: :bold
      pdf.text "🌟 Strengths"
      pdf.move_down 5
      
      pdf.font "Helvetica", size: 12
      strengths.each do |strength|
        pdf.text "• #{strength}", indent_paragraphs: 20
      end
      pdf.move_down 10
    end

    if improvement_areas.any?
      pdf.font "Helvetica", size: 14, style: :bold
      pdf.text "🎯 Areas for Improvement"
      pdf.move_down 5
      
      pdf.font "Helvetica", size: 12
      improvement_areas.each do |area|
        recommendation = get_recommendation_for_area(area)
        pdf.text "• #{area}: #{recommendation}", indent_paragraphs: 20
        pdf.move_down 5
      end
    end

    # Add general recommendations
    pdf.move_down 10
    pdf.font "Helvetica", size: 14, style: :bold
    pdf.text "💡 General Recommendations"
    pdf.move_down 5
    
    pdf.font "Helvetica", size: 12
    general_recommendations.each do |recommendation|
      pdf.text "• #{recommendation}", indent_paragraphs: 20
      pdf.move_down 3
    end

    pdf.move_down 20
  end

  def add_footer(pdf)
    pdf.number_pages "<page> of <total>", 
                     at: [0, 0], 
                     align: :center, 
                     size: 10

    pdf.stroke_horizontal_rule
    pdf.move_down 10
    
    pdf.font "Helvetica", size: 10
    pdf.text "This report was generated by the Legal Simulation Platform", align: :center
    pdf.text "For questions about your performance, contact your instructor", align: :center
  end

  def get_recommendation_for_area(area)
    recommendations = {
      "Settlement Strategy" => "Focus on understanding client needs and market conditions. Research comparable settlements and practice justifying your offers with strong legal reasoning.",
      "Legal Reasoning" => "Strengthen your legal research skills. Cite relevant precedents and statutes. Practice building logical arguments that connect facts to legal principles.",
      "Team Collaboration" => "Increase participation in team discussions. Share research findings and actively contribute to strategy development. Practice active listening and constructive feedback.",
      "Process Efficiency" => "Develop better time management skills. Create templates for common tasks and establish clear decision-making processes with your team."
    }
    
    recommendations[area] || "Continue developing your skills in this area through practice and feedback."
  end

  def general_recommendations
    return [] unless current_performance_score

    recommendations = []
    total_score = current_performance_score.total_score

    if total_score >= 90
      recommendations << "Excellent work! Consider mentoring other students and taking on leadership roles."
      recommendations << "Focus on maintaining consistency and exploring advanced negotiation techniques."
    elsif total_score >= 80
      recommendations << "Strong performance overall. Focus on identifying and addressing your weakest areas."
      recommendations << "Consider additional legal research to strengthen your argument quality."
    elsif total_score >= 70
      recommendations << "Good foundation with room for improvement. Focus on consistent participation and preparation."
      recommendations << "Work on time management to improve efficiency scores."
    else
      recommendations << "Significant improvement needed. Consider meeting with your instructor for additional support."
      recommendations << "Focus on basic preparation and active participation in team activities."
    end

    # Add bonus-specific recommendations
    if (current_performance_score.speed_bonus || 0) == 0
      recommendations << "Work on improving response times to earn speed bonuses."
    end

    if (current_performance_score.creative_terms_score || 0) < 3
      recommendations << "Consider creative non-monetary terms in your settlement offers."
    end

    recommendations
  end
end