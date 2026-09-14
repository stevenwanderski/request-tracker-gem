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

    # Small stand-in for the active_link_to gem: highlights a nav link when
    # the current request is under (or exactly at) its path.
    def nav_link_to(text, path, exact: false)
      active = exact ? current_page?(path) : request.path.start_with?(path)
      link_to text, path, class: (active ? "active" : nil)
    end
  end
end
