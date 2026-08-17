require "nokogiri"

module RequestTracker
  module BodyScrubber
    REDACTED = "[REDACTED]".freeze

    # A run of 13-19 digits, optionally separated by spaces or dashes, that
    # passes a Luhn checksum. Runs against every string value regardless of
    # field name, so a PAN sitting under a field name that isn't on
    # config.scrubbed_fields (or with no field name at all) still gets caught.
    # Anchored to start and end on a digit so a trailing separator in
    # surrounding text isn't swallowed into the match.
    PAN_PATTERN = /\b\d(?:[ -]?\d){12,18}\b/.freeze

    def self.scrub_body(raw_body, content_type)
      return raw_body if raw_body.nil?

      if content_type&.include?("json")
        begin
          scrub_json(JSON.parse(raw_body))
        rescue JSON::ParserError
          scrub_string(raw_body)
        end
      elsif content_type&.include?("xml")
        scrub_xml(raw_body)
      else
        scrub_string(raw_body)
      end
    end

    def self.scrub_json(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, val), scrubbed|
          scrubbed[key] = sensitive_field?(key) ? REDACTED : scrub_json(val)
        end
      when Array
        value.map { |v| scrub_json(v) }
      when String
        scrub_string(value)
      else
        value
      end
    end

    # Parsed and walked rather than regex-matched against the raw string, so
    # this survives whitespace, attributes, CDATA, and namespaced tags (the
    # Authorize.Net schema wraps everything in a default namespace, and
    # Nokogiri's #name already strips that prefix, so matching against
    # scrubbed_fields works the same as it does for a plain, unnamespaced doc).
    def self.scrub_xml(xml_string)
      doc = Nokogiri::XML(xml_string) { |config| config.strict }
      return scrub_string(xml_string) if doc.root.nil?

      doc.traverse do |node|
        if node.element?
          node.attribute_nodes.each do |attr|
            attr.value = sensitive_field?(attr.name) ? REDACTED : scrub_string(attr.value)
          end
        elsif node.text? && !node.content.strip.empty?
          field_name = node.parent&.name
          node.content = sensitive_field?(field_name) ? REDACTED : scrub_string(node.content)
        end
      end

      doc.to_xml
    rescue Nokogiri::XML::SyntaxError
      scrub_string(xml_string)
    end

    def self.scrub_string(str)
      return str if !str.is_a?(String)

      str.gsub(PAN_PATTERN) { |match| luhn_valid?(match) ? REDACTED : match }
    end

    def self.sensitive_field?(name)
      return false if name.nil?

      RequestTracker.config.scrubbed_fields.any? { |field| field.casecmp?(name) }
    end

    def self.luhn_valid?(number)
      digits = number.delete(" -").chars.map(&:to_i)
      return false if digits.length < 13

      sum = digits.reverse.each_with_index.sum do |digit, index|
        next digit if index.even?

        doubled = digit * 2
        doubled > 9 ? doubled - 9 : doubled
      end

      sum % 10 == 0
    end
  end
end
