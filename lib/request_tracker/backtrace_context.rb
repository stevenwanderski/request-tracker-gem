module RequestTracker
  # Runs inside the app that raised, so (unlike the dashboard) it has the
  # source files on disk. Mirrors what ActionDispatch::ExceptionWrapper does
  # for Rails' own development error page: a few lines of context around each
  # app frame, plus the ^^^^^ caret from Ruby's built-in error_highlight when
  # it can pinpoint the exact sub-expression that raised.
  module BacktraceContext
    CONTEXT_LINES_BEFORE = 3
    CONTEXT_LINES_AFTER = 3

    # Reading source files for every frame of a pathological (e.g. deeply
    # recursive) backtrace would add unbounded I/O before the original
    # exception can keep propagating -- cap it well below where that matters.
    MAX_ANNOTATED_FRAMES = 50

    LOCATION_PATTERN = /\A(.+):(\d+):in [`'](.*)['`]\z/
    LINE_ONLY_PATTERN = /\A(.+):(\d+)\z/

    def self.build(exception)
      backtrace = exception.backtrace
      return [] if backtrace.nil?

      locations = exception.backtrace_locations || []
      annotated = 0

      backtrace.each_with_index.map do |line, index|
        next line if !in_app?(line) || annotated >= MAX_ANNOTATED_FRAMES

        code = source_context(line, locations[index], exception)
        next line unless code

        annotated += 1
        { "text" => line, "code" => code }
      end
    # Never let context extraction take down the actual error report -- the
    # raw backtrace is always more important than the enrichment.
    rescue StandardError
      Array(exception.backtrace)
    end

    def self.in_app?(line)
      !line.include?("/gems/")
    end
    private_class_method :in_app?

    def self.source_context(line, location, exception)
      path, lineno = parse_location(line)
      return nil unless path && lineno
      return nil unless File.exist?(path) && File.readable?(path)

      source_lines = File.readlines(path)
      start_index = [lineno - 1 - CONTEXT_LINES_BEFORE, 0].max
      end_index = [lineno - 1 + CONTEXT_LINES_AFTER, source_lines.length - 1].min

      {
        "start_line" => start_index + 1,
        "lines" => source_lines[start_index..end_index].map(&:chomp),
        "error_line" => lineno,
        "highlight" => highlight_for(exception, location)
      }.compact
    rescue SystemCallError, IOError
      nil
    end
    private_class_method :source_context

    def self.parse_location(line)
      match = line.match(LOCATION_PATTERN) || line.match(LINE_ONLY_PATTERN)
      return nil unless match

      [match[1], match[2].to_i]
    end
    private_class_method :parse_location

    def self.highlight_for(exception, location)
      return nil unless error_highlight_available? && location.is_a?(Thread::Backtrace::Location)

      spot = ErrorHighlight.spot(exception, backtrace_location: location)
      return nil unless spot

      {
        "line" => spot[:first_lineno],
        "start_col" => spot[:first_column],
        "end_col" => spot[:last_column]
      }
    rescue StandardError
      nil
    end
    private_class_method :highlight_for

    # ErrorHighlight.spot's backtrace_location: keyword requires >= 0.4.0.
    def self.error_highlight_available?
      defined?(ErrorHighlight) && Gem::Version.new(ErrorHighlight::VERSION) >= Gem::Version.new("0.4.0")
    rescue StandardError
      false
    end
    private_class_method :error_highlight_available?
  end
end
