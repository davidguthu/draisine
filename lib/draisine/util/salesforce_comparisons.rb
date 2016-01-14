module Draisine
  module SalesforceComparisons
    JSON_TIME_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(.\d{3})?[+\-]\d{2}:\d{2}\z/
    module_function

    def salesforce_equals?(value, other)
      value = salesforce_coerce(value)
      other = salesforce_coerce(other)
      return value == other if value.class != other.class

      case value
      when String
        normalize_string(value) == normalize_string(other)
      else
        value == other
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
      string.gsub("\r\n", "\n")
    end
  end
end