module RequestTracker
  class ConfigurationError < StandardError
    def initialize(missing_keys)
      message = <<~MSG
        RequestTracker is missing the required environment variable(s):
          #{missing_keys.join("\n  ")}

        Set these in your environment (or .env file) before booting the app.
      MSG

      super(message)
    end

    def backtrace
      nil
    end
  end
end