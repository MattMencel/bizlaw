class AnnotationsController < ApplicationController
  include ImpersonationReadOnly

  before_action :authenticate_user!

  def index
    @annotations = current_user.annotations.page(params[:page])
  end

  def show
    @annotation = current_user.annotations.find(params[:id])
  end

  def create
    @annotation = current_user.annotations.build(annotation_params)

    if @annotation.save
      redirect_to @annotation, notice: "Annotation created successfully."
    else
      render :new
    end
  end

  def edit
    @annotation = current_user.annotations.find(params[:id])
  end

  def update
    @annotation = current_user.annotations.find(params[:id])

    if @annotation.update(annotation_params)
      redirect_to @annotation, notice: "Annotation updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @annotation = current_user.annotations.find(params[:id])
    @annotation.destroy
    redirect_to annotations_path, notice: "Annotation deleted successfully."
  end

  def search
    @query = params[:q]
    @annotations = current_user.annotations.where("content ILIKE ?", "%#{@query}%").page(params[:page])
  end

  private

  def annotation_params
    params.require(:annotation).permit(:content, :document_id, :x_position, :y_position, :page_number)
  end
end
