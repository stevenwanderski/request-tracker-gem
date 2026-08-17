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

    DEFAULT_SCRUBBED_FIELDS = %w[
      cardNumber card_number cardCode card_code
      cvv cvv2 cvc cvc2
      expirationDate expiration_date
      accountNumber account_number routingNumber routing_number
      bankAccountNumber bank_account_number
    ].freeze

    def initialize
      @enabled_environments = []
      @current_user = nil
      @scrubbed_fields = DEFAULT_SCRUBBED_FIELDS.dup
    end
  end
end
