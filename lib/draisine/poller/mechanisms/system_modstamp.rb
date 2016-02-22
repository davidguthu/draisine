module Draisine
  class Poller
    module Mechanisms
      class SystemModstamp < Base
        def get_updated_ids(start_date, end_date)
          response = client.query <<-EOQ
          SELECT Id FROM #{salesforce_object_name}
          WHERE SystemModstamp >= #{start_date.iso8601}
          AND SystemModstamp <= #{end_date.iso8601}
          EOQ
          response.map(&:Id)
        end

        def get_deleted_ids(start_date, end_date)
          []
        end
      end
    end
  end
end
