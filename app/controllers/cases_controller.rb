class CasesController < ApplicationController
  def index
    @cases = Case.page(params[:page])
    @case_types = CaseType.all
  end

  def show
  end

  def new
  end

  def edit
  end
end
