module RequestTracker
  module ApplicationHelper
    # Bundler always installs gems under a "/gems/" segment regardless of the
    # reporting app's deploy layout, so it's a reliable app-vs-framework signal
    # even though we only ever see raw backtrace strings, not live frame objects.
    def in_app_backtrace_line?(line)
      !backtrace_line_text(line).include?("/gems/")
    end

    # Backtrace entries are either a plain String (older records, or gem
    # frames the reporting client didn't annotate) or a Hash with a "text" key
    # plus source context -- see RequestTracker::BacktraceContext in the gem.
    def backtrace_line_text(line)
      line.is_a?(Hash) ? line["text"] : line
    end

    def backtrace_line_code(line)
      line["code"] if line.is_a?(Hash)
    end

    # The current_user callback can return a scalar (an id, an email) or an
    # arbitrary object serialized via #as_json -- render scalars as-is and
    # compact anything else to fit a single table cell.
    def current_user_display(value)
      return nil if value.blank?

      value.is_a?(String) || value.is_a?(Numeric) ? value.to_s : value.to_json
    end

    # Requests captured before user agent tracking shipped, or from clients
    # that don't send one (scripts, curl), have no browser to name -- fall
    # back to a labeled "Unknown" rather than leaving the cell blank.
    def browser_label(browser)
      browser.presence || "Unknown"
    end

    # Bodies arrive as whatever was captured: an already-parsed Hash/Array,
    # a JSON string, an XML document, or a raw application/x-www-form-urlencoded
    # string (e.g. "foo=bar&baz=qux"). Decode/indent these so they pretty-print
    # instead of showing up as one long line -- or, for XML, getting misread as
    # form data since tag attributes ("version=...") also contain "=".
    def pretty_body(body)
      return nil if body.blank?
      return JSON.pretty_generate(body) unless body.is_a?(String)

      stripped = body.strip

      if stripped.match?(/\A<[?\/a-zA-Z!]/)
        begin
          doc = Nokogiri::XML(stripped) { |config| config.strict.noblanks }
          return doc.to_xml(indent: 2, save_with: Nokogiri::XML::Node::SaveOptions::FORMAT) if doc.errors.none? { |e| e.error? || e.fatal? }
        rescue Nokogiri::XML::SyntaxError
          # fall through and return the raw string below
        end
        return body
      end

      if stripped.match?(/\A[\[{]/)
        begin
          return JSON.pretty_generate(JSON.parse(stripped))
        rescue JSON::ParserError
          return body
        end
      end

      if stripped.match?(/\A[\w.\[\]%+-]+=[^&]*(&[\w.\[\]%+-]+=[^&]*)*\z/)
        parsed = Rack::Utils.parse_nested_query(body)
        return JSON.pretty_generate(parsed) if parsed.present?
      end

      body
    end

    # Turbo frames, fetch/XHR calls, and link prefetches all ride along on the
    # same session as real page views, so a journey timeline would otherwise
    # bury "landed on /donate" under a pile of polling. Judged from the
    # captured request headers, since that's all that survives to read time.
    def background_request?(request)
      headers = request.headers || {}
      accept = headers["Accept"].to_s

      headers["Turbo-Frame"].present? ||
        headers["X-Requested-With"] == "XMLHttpRequest" ||
        headers["Sec-Purpose"].to_s.include?("prefetch") ||
        headers["Purpose"] == "prefetch" ||
        (accept.present? && !accept.include?("text/html") && !accept.include?("*/*"))
    end

    # Time since the previous step, compact enough to sit in a timeline gutter.
    def elapsed_label(seconds)
      seconds = seconds.round
      return "+#{seconds}s" if seconds < 60
      return "+#{seconds / 60}m #{seconds % 60}s" if seconds < 3600

      "+#{seconds / 3600}h #{(seconds % 3600) / 60}m"
    end

    def journey_status_badge_class(status_code)
      case status_code.to_s
      when /\A5/ then "badge-red"
      when /\A4/ then "badge-amber"
      when /\A3/ then "badge-blue"
      else "badge-green"
      end
    end

    # Small stand-in for the active_link_to gem: highlights a nav link when
    # the current request is under (or exactly at) its path.
    def nav_link_to(text, path, exact: false)
      active = exact ? current_page?(path) : request.path.start_with?(path)
      link_to text, path, class: (active ? "active" : nil)
    end
  end
end
