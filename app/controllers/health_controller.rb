class HealthController < ApplicationController
  def check
    render json: {status: "ok", timestamp: Time.current}
  end
end
