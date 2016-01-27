require 'rails/generators/active_record'

module Draisine
  class DeltaMigrationGenerator < Rails::Generators::Base
    self.source_root(File.expand_path('../templates/', __FILE__))

    desc <<-DESC
    Generates a migration for missing columns for given model
    DESC

    argument :model, type: :string,
                     banner: "ModelName",
                     desc: "Model name for active record (e.g. Lead)",
                     required: true
    argument :salesforce_object_name, type: :string,
                     banner: "SalesforceObjectName",
                     desc: "Salesforce object name (inferred from ModelName by default)",
                     required: false
    def generate
      @model_name = model.classify.singularize
      @model_file = "app/models/#{model.underscore.singularize}.rb"
      @table_name = model.underscore.gsub("/", "_").pluralize
      @migration_title = "DeltaUpdateSalesforce#{model.classify.gsub('::', '').pluralize}#{migration_uid}"
      @migration_file = existing_migration_name(@migration_title) ||
                        "db/migrate/#{migration_number}_#{@migration_title.underscore}.rb"

      @salesforce_object_name = salesforce_object_name || model.classify.demodulize
      @materialized_model = Draisine.salesforce_client.materialize(@salesforce_object_name)
      @mapper = Draisine::TypeMapper.new(@materialized_model.type_map)
      @existing_columns = ActiveRecord::Base.connection.columns(@table_name).map(&:name)
      @ar_col_defs = @mapper.active_record_column_defs
                            .reject {|col_def| @existing_columns.include?(col_def.column_name) }

      template "delta_migration.rb", @migration_file
    end

    protected

    def migration_number
      Time.current.utc.strftime("%Y%m%d%H%M%S")
    end

    def migration_uid
      Time.current.utc.strftime("%Y%m%d")
    end

    # This is needed for rails destroy to work, since every time we generate a new name for our migration
    def existing_migration_name(migration_title)
      Dir.glob("#{Rails.root}/db/migrate/[0-9]*_#{migration_title.underscore}.rb").first
    end
  end
end