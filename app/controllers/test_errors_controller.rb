class TestErrorsController < ApplicationController
  def not_found
    raise ActiveRecord::RecordNotFound, "Record not found"
  end

  def parameter_missing
    params.require(:required_param)
  end

  def standard_error
    raise StandardError, "Something went wrong"
  end
end
