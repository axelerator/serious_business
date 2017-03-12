require 'rails/generators'
require 'rails/generators/migration'

module SeriousBusiness
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      class_option :primary_key_type, :optional => true, :type => :string, :banner => "primary_key_type",
                   :desc => "Set to uuid if you're using uuid as primary key type"

      # Copy the initializer file to config/initializers folder.
      def copy_initializer_file
        template "initializer.rb", "config/initializers/serious_business.rb"
      end

      # Copy the migrations files to db/migrate folder
      def copy_migration_files
        # Copy core migration file in all cases except when you pass --only-submodules.
        return unless defined?(SeriousBusiness::Generators::InstallGenerator::ActiveRecord)
        migration_template "migration/actions.rb", "db/migrate/create_serious_business.rb", migration_class_name: migration_class_name

      end

      # Define the next_migration_number method (necessary for the migration_template method to work)
      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          sleep 1 # make sure each time we get a different timestamp
          Time.new.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end

      private

      def migration_class_name
        if Rails::VERSION::MAJOR >= 5
          "ActiveRecord::Migration[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        else
          "ActiveRecord::Migration"
        end
      end

    end
  end
end
