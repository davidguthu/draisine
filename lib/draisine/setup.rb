require "logger"

module Draisine
  def self.salesforce_client=(client)
    @salesforce_client = client
  end

  def self.salesforce_client
    unless @salesforce_client
      fail <<-EOM
DatabaseDotcom client was not properly set up. You can set it up as follows:
sf_client = Databasedotcom::Client.new("config/databasedotcom.yml")
sf_client.authenticate :username => <username>, :password => <password>
Draisine.salesforce_client = sf_client
EOM
    end
    @salesforce_client
  end

  def self.organization_id
    unless @organization_id
      fail <<-EOM
Draisine.organization_id was not properly set up.
You can use Draisine.organization_id= method to set it.
See https://cloudjedi.wordpress.com/no-fuss-salesforce-id-converter/ if
you need to convert your 15-char id into 18-char.
EOM
    end
    @organization_id
  end

  def self.organization_id=(id)
    unless id.kind_of?(String) && id.length == 18
      fail ArgumentError, "You should set organization id to an 18 character string"
    end
    @organization_id = id
  end

  def self.job_error_handler
    @job_error_handler ||= proc {|error, job_instance, args| raise error }
  end

  def self.job_error_handler=(handler)
    @job_error_handler = handler
  end

  def self.poll_locally_updated_ids?
    @poll_locally_updated_ids = true if @poll_locally_updated_ids.nil?
    @poll_locally_updated_ids
  end

  def self.poll_locally_updated_ids=(value)
    @poll_locally_updated_ids = value
  end

  def self.sync_callback
    @sync_callback ||= proc {|type, salesforce_id, options| }
  end

  def self.sync_callback=(callback)
    @sync_callback = callback
  end

  def self.job_retry_attempts
    @job_retry_attempts ||= 0
  end

  def self.sync_soap_operations?
    @sync_soap_operations = true if @sync_soap_operations.nil?
    @sync_soap_operations
  end

  def self.sync_soap_operations=(value)
    @sync_soap_operations = value
  end

  def self.job_retry_attempts=(count)
    @job_retry_attempts = count
  end

  def self.invalid_organization_handler
    @invalid_organization_handler ||= proc {|message| fail Draisine::SoapHandler::InvalidOrganizationError, "invalid organization id in the inbound message from salesforce" }
  end

  def self.invalid_organization_handler=(handler)
    @invalid_organization_handler = handler
  end

  # https://help.salesforce.com/apex/HTViewSolution?language=en_US&id=000003652
  def self.allowed_ip_ranges
    @allowed_ip_ranges ||= [
      '96.43.144.0/20',
      '136.146.210.8/15',
      '204.14.232.0/21',
      '85.222.128.0/19',
      '185.79.140.0/22',
      '182.50.76.0/22',
      '202.129.242.0/23',
      '127.0.0.1'
    ]
  end

  def self.allowed_ip_ranges=(ranges)
    @allowed_ip_ranges = ranges
  end
end
