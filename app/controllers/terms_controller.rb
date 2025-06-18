# frozen_string_literal: true

class TermsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_term, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_authorized_user
  before_action :ensure_can_modify_term, only: [ :edit, :update, :destroy ]

  def index
    @terms = current_user_terms.includes(:courses)
                              .order(:academic_year, :start_date)
                              .page(params[:page]).per(20)

    @current_terms = @terms.current
    @upcoming_terms = @terms.upcoming.limit(5)

    respond_to do |format|
      format.html
      format.json { render json: @terms }
    end
  end

  def show
    @courses = @term.courses.includes(:instructor, :students)

    respond_to do |format|
      format.html
      format.json { render json: @term }
    end
  end

  def new
    # Admins can create terms for any organization, others for their own
    organization = current_user.admin? ? Organization.new : current_user_organization
    @term = organization.terms.build
    set_default_dates

    # For admins, provide organization options
    @organizations = current_user.admin? ? Organization.includes(:courses).all : [ current_user_organization ]
  end

  def create
    # Determine which organization to create the term for
    organization = current_user.admin? && params[:term][:organization_id].present? ?
                     Organization.find(params[:term][:organization_id]) :
                     current_user_organization

    @term = organization.terms.build(term_params)

    if @term.save
      redirect_to @term, notice: "Term was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @term.update(term_params)
      redirect_to @term, notice: "Term was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @term.courses.exists?
      redirect_to terms_path, alert: "Cannot delete term with existing courses."
    else
      @term.soft_delete
      redirect_to terms_path, notice: "Term was successfully deleted."
    end
  end

  private

  def set_term
    @term = current_user_terms.find(params[:id])
  end

  def current_user_terms
    if current_user.admin?
      # Admins can see all terms across all organizations
      Term.all
    elsif current_user.org_admin?
      # Org admins can see terms in their organization
      current_user_organization.terms
    else
      # Instructors can see terms in their organization
      current_user_organization.terms
    end
  end

  def current_user_organization
    @current_user_organization ||= current_user.organization ||
                                   Organization.find_by(domain: current_user.email.split("@").last)
  end

  def ensure_authorized_user
    unless current_user.instructor? || current_user.org_admin? || current_user.admin?
      redirect_to root_path, alert: "Access denied. You must be an instructor, organization admin, or system admin to manage terms."
    end
  end

  def can_modify_term?(term)
    return true if current_user.admin?
    return true if current_user.org_admin? && term.organization == current_user_organization
    return true if current_user.instructor? && term.organization == current_user_organization
    false
  end

  def ensure_can_modify_term
    unless can_modify_term?(@term)
      redirect_to terms_path, alert: "You are not authorized to modify this term."
    end
  end

  def set_default_dates
    current_year = Date.current.year
    # Default to fall semester
    @term.start_date = Date.new(current_year, 8, 15) # Mid August
    @term.end_date = Date.new(current_year, 12, 15)  # Mid December
    @term.academic_year = current_year
  end

  def term_params
    permitted_params = [ :term_name, :academic_year, :start_date, :end_date, :description, :active ]
    permitted_params << :organization_id if current_user.admin?
    params.require(:term).permit(permitted_params)
  end
end
