module RequestTracker
  class Configuration
    attr_accessor :enabled_environments

    def initialize
      @enabled_environments = []
    end
  end
end