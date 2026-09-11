module RequestTracker
  class Configuration
    attr_accessor :enabled_environments

    # A callable that receives the ActionDispatch::Request and returns
    # whatever should represent the current user for that request -- an ID,
    # an email, or the whole user object. Left unset, no user is recorded.
    # Set it in an initializer:
    #
    #   RequestTracker.configure do |config|
    #     config.current_user = ->(request) { request.env["warden"]&.user }
    #   end
    attr_accessor :current_user

    # Field names (JSON keys, or XML element/attribute local names, case
    # insensitive) whose value gets replaced with "[REDACTED]" wherever they
    # appear in an outbound call's request or response body. Extend rather
    # than replace, so the payment-processor defaults stay in place:
    #
    #   RequestTracker.configure do |config|
    #     config.scrubbed_fields += %w[ssn bankAccountNumber]
    #   end
    attr_accessor :scrubbed_fields

    # Header names (case insensitive) whose value gets replaced with
    # "[REDACTED]" wherever they appear in a captured request's headers.
    # Extend rather than replace, so the auth/session defaults stay in place:
    #
    #   RequestTracker.configure do |config|
    #     config.scrubbed_headers += %w[X-Internal-Signature]
    #   end
    #
    # Headers not on this list are still checked against a substring fallback
    # (name containing "token", "secret", "key", "auth", "session", "cookie",
    # or "password") in BodyScrubber.sensitive_header?, so most custom auth
    # headers are caught even without being added here explicitly.
    attr_accessor :scrubbed_headers

    DEFAULT_SCRUBBED_FIELDS = %w[
      cardNumber card_number cardCode card_code
      cvv cvv2 cvc cvc2
      expirationDate expiration_date
      accountNumber account_number routingNumber routing_number
      bankAccountNumber bank_account_number
    ].freeze

    DEFAULT_SCRUBBED_HEADERS = %w[
      Authorization Cookie Set-Cookie Proxy-Authorization
      X-Api-Key X-Auth-Token X-Csrf-Token
    ].freeze

    def initialize
      @enabled_environments = []
      @current_user = nil
      @scrubbed_fields = DEFAULT_SCRUBBED_FIELDS.dup
      @scrubbed_headers = DEFAULT_SCRUBBED_HEADERS.dup
    end
  end
end
