# frozen_string_literal: true

require "gemini-ai"

# Google AI (Gemini) Configuration
module GoogleAI
  class << self
    def configure
      return unless enabled?

      @client = Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: api_key
        },
        options: {
          model: model,
          server_sent_events: true
        }
      )
    end

    def client
      @client ||= configure
    end

    def enabled?
      api_key.present?
    end

    def api_key
      ENV.fetch("GOOGLE_AI_API_KEY", nil)
    end

    def model
      ENV.fetch("GEMINI_MODEL", "gemini-2.0-flash-lite")
    end
  end
end

# Initialize the client if API key is present
GoogleAI.configure if GoogleAI.enabled?
