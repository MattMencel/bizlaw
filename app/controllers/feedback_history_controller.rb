class FeedbackHistoryController < ApplicationController
  include ImpersonationReadOnly

  before_action :authenticate_user!

  def index
    @feedback_entries = current_user.received_feedback.order(created_at: :desc).page(params[:page])
    @feedback_stats = FeedbackAnalysisService.generate_stats(current_user)
  end

  def show
    @feedback = current_user.received_feedback.find(params[:id])
  end

  def search
    @query = params[:q]
    @feedback_type = params[:feedback_type]

    feedback = current_user.received_feedback

    if @query.present?
      feedback = feedback.where("content ILIKE ? OR title ILIKE ?", "%#{@query}%", "%#{@query}%")
    end

    if @feedback_type.present?
      feedback = feedback.where(feedback_type: @feedback_type)
    end

    @feedback_entries = feedback.order(created_at: :desc).page(params[:page])

    render :index
  end

  def export
    @feedback_entries = current_user.received_feedback.order(created_at: :desc)

    respond_to do |format|
      format.csv {
        send_data FeedbackExportService.to_csv(@feedback_entries),
          filename: "feedback_history_#{Date.current}.csv",
          type: "text/csv"
      }
      format.pdf {
        pdf = FeedbackExportService.to_pdf(@feedback_entries)
        send_data pdf.render,
          filename: "feedback_history_#{Date.current}.pdf",
          type: "application/pdf"
      }
    end
  end

  private

  def feedback_params
    params.permit(:q, :feedback_type, :start_date, :end_date)
  end
end
