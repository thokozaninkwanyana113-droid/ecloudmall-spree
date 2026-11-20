require 'rails/generators'

module Spree
  module Marketplace
    module Generators
      # rails g spree:marketplace:install — copies migrations and runs them
      class InstallGenerator < Rails::Generators::Base
        class_option :migrate, type: :boolean, default: true

        def add_migrations
          run 'bin/rails railties:install:migrations FROM=spree_marketplace'
        end

        def run_migrations
          run 'bin/rails db:migrate' if options[:migrate]
        end
      end
    end
  end
end
