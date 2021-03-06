module Draisine
  module SalesforceComparisons
    JSON_TIME_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(.\d{3})?[+\-]\d{2}:\d{2}\z/
    EPSILON = 1e-10
    module_function

    def salesforce_equals?(value, other)
      value = salesforce_cleanup(value)
      other = salesforce_cleanup(other)
      value = salesforce_coerce(value)
      other = salesforce_coerce(other)

      return fp_equals?(value, other) if numeric?(value) && numeric?(other)
      return value == other if value.class != other.class

      case value
      when String
        normalize_string(value) == normalize_string(other)
      else
        value == other
      end
    end

    def salesforce_cleanup(value)
      case value
      when String
        Draisine::Encoding.convert_to_utf_and_sanitize(value)
      else
        value
      end
    end

    def salesforce_coerce(value)
      if value.kind_of?(DateTime) || value.kind_of?(Time) || value.kind_of?(Date) ||
         value =~ JSON_TIME_REGEX
        value = value.to_time.utc.change(usec: 0)
      end
      value
    end

    def normalize_string(string)
      string.gsub(/\W/, "")
    end

    def fp_equals?(value, other)
      (value - other).abs <= EPSILON
    end

    def numeric?(value)
      value.kind_of?(Numeric)
    end
  end
end
