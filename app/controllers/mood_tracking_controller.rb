class MoodTrackingController < ApplicationController
  include ImpersonationReadOnly

  before_action :authenticate_user!
  before_action :set_mood_entry, only: [:show, :update_mood]

  def index
    @mood_entries = current_user.mood_entries.order(created_at: :desc).page(params[:page])
    @current_mood = current_user.mood_entries.order(created_at: :desc).first
  end

  def show
    # Individual mood entry details
  end

  def create
    @mood_entry = current_user.mood_entries.build(mood_params)

    if @mood_entry.save
      redirect_to mood_tracking_index_path, notice: "Mood entry recorded successfully."
    else
      redirect_to mood_tracking_index_path, alert: "Error recording mood entry."
    end
  end

  def update_mood
    if @mood_entry.update(mood_params)
      redirect_to mood_tracking_index_path, notice: "Mood updated successfully."
    else
      redirect_to mood_tracking_index_path, alert: "Error updating mood."
    end
  end

  def history
    @mood_entries = current_user.mood_entries.order(created_at: :desc).page(params[:page])
    @mood_trends = MoodAnalysisService.analyze_trends(current_user)
  end

  def analytics
    @mood_data = MoodAnalysisService.generate_analytics(current_user)
    @weekly_trends = MoodAnalysisService.weekly_trends(current_user)
    @stress_patterns = MoodAnalysisService.stress_patterns(current_user)
  end

  private

  def set_mood_entry
    @mood_entry = current_user.mood_entries.find(params[:id])
  end

  def mood_params
    params.require(:mood_entry).permit(:mood_level, :stress_level, :confidence_level, :notes, :case_id)
  end
end
