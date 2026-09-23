# frozen_string_literal: true

class InertiaController < ApplicationController
  # Share data with all Inertia responses
  # see https://inertia-rails.dev/guide/shared-data
  #   inertia_share user: -> { Current.user&.as_json(only: [:id, :name, :email]) }

  # PROTOTYPE — voice prototype (#388), branch prototype/voice only. `?voice=a|b|c`
  # swaps the sample strings; `?voice=o` returns to the original. Held in the
  # session so it survives the redirect after an act.
  VOICES = %w[a b c].freeze
  around_action :with_prototype_voice
  inertia_share voice: -> {
    v = session[:prototype_voice]
    v ? {key: v, strings: I18n.t("prototype_voice")} : {key: "o", strings: {}}
  }

  private

  def with_prototype_voice(&)
    if params.key?(:voice)
      session[:prototype_voice] = VOICES.include?(params[:voice]) ? params[:voice] : nil
    end
    v = session[:prototype_voice]
    I18n.with_locale(v ? :"en-#{v}" : :en, &)
  end
end
