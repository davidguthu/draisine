require "active_record"
require "spec_helper"

Draisine.register_ar_macro

ActiveRecord::Base.establish_connection('sqlite3::memory:')

ActiveRecord::Schema.define(:version => 1) do
  create_table "leads", :force => true do |t|
    t.string :FirstName
    t.string :LastName
    t.string :custom_attribute
    t.string :non_sf_attribute
    t.datetime :SystemModstamp

    t.string :salesforce_id
    t.datetime :salesforce_updated_at
    t.timestamps null: false
    t.index :salesforce_id, unique: true
  end
end

class Lead < ActiveRecord::Base
  salesforce_syncable synced_attributes: [:FirstName, :LastName, :CustomAttribute__c],
    mapping: {:CustomAttribute__c => :custom_attribute},
    operations: Draisine::ALL_OPS,
    sync: true

  def self.create_without_callbacks!(attrs)
    model = new(attrs)
    model.salesforce_skip_sync = true
    model.save!
    model.salesforce_skip_sync = false
    model
  end
end

RSpec.configure do |c|
  c.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
