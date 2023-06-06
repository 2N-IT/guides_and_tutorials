# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  gem 'tty-prompt'
end

add_source 'https://rubygems.org'

prompt = TTY::Prompt.new

view_components = prompt.yes?('Install GithubViewComponent? (A better Trailblazer Cells)')

if view_components
  gem 'view_component'
  run 'mkdir app/components'
end

question = 'Choose your API type'
choices = %w[None REST GraphQL Both]
api_answer = prompt.select(question, choices)

if api_answer.in?(%w[REST Both])
  gem 'grape'
  gem 'grape-entity'
  gem 'grape-swagger'
  gem 'grape-swagger-entity'
  gem 'grape-swagger-rails'
  after_bundle do
    route "mount GrapeSwaggerRails::Engine => '/swagger'"
  end
end

if api_answer.in?(%w[GraphQL Both])
  gem 'graphql'
  gem 'graphiql-rails'

  after_bundle do
    run 'rails g graphql:install'
  end
end

gem 'rack-cors', require: 'rack/cors' if api_answer != 'None'

question = 'What is your desired authentication tool, if any?'
choices = %w[None rodauth sorcery devise]
authentication_tool = prompt.select(question, choices)

case authentication_tool
when 'devise'
  gem 'devise', git: 'https://github.com/heartcombo/devise', branch: 'main'

  generate_model = prompt.yes?('Generate devise model?')
  devise_model = prompt.ask('Name your user model', default: 'User')

  after_bundle do
    run 'rails g devise:install'
    run "rails g devise #{devise_model.nil? ? 'User' : devise_model.classify}" if generate_model
  end
when 'rodauth'
  gem 'rodauth-rails'
  question = 'Use rodauth for JSON API? What mode if yes'
  choices = %w[No JSON JWT]
  json_mode = prompt.select(question, choices)
  json_mode = json_mode == 'No' ? '' : "--#{json_mode.downcase}"

  after_bundle do
    run "rails generate rodauth:install #{json_mode}"
  end
when 'sorcery'
  gem 'sorcery'

  model_name = prompt.ask('Name your user model', default: 'User')
  after_bundle do
    command = 'rails generate sorcery:install'
    command += " --model #{model_name.classify}" if model_name
    run command
  end
end

question = 'Choose your administration framework'
choices = ['None', 'Active Admin', 'Administrate']
admin_answer = prompt.select(question, choices)

case admin_answer
when 'Active Admin'
  gem 'activeadmin'

  if authentication_tool == 'devise'
    after_bundle do
      run 'rails g active_admin:install'
    end
  elsif yes?('Install Devise for Active Admin?')
    gem 'devise', git: 'https://github.com/heartcombo/devise', branch: 'main'
    after_bundle do
      run 'rails g active_admin:install'
    end
  else
    after_bundle do
      run 'rails g active_admin:install --skip-users'
    end
  end
when 'Administrate'
  gem 'administrate'

  after_bundle do
    run 'rails g administrate:install'
  end
end

if prompt.yes?('Install file storage library?')
  question = 'Choose your file storage approach'
  choices = ['Active Storage', 'Shrine', 'Carrierwave']
  file_answer = prompt.select(question, choices)

  case file_answer
  when 'Active Storage'
    after_bundle do
      run 'rails active_storage:install'
    end
  when 'Shrine'
    gem 'shrine'
  when 'Carrierwave'
    gem 'carrierwave'
  end

  gem 'aws-sdk-s3' if prompt.yes?('Install AWS SDK for S3?')
end

if prompt.yes?('Install Sidekiq?')
  gem 'sidekiq'
  gem 'sidekiq-scheduler'
  after_bundle do
    inject_into_file 'config/routes.rb', before: 'Rails.application.routes' do
      "require 'sidekiq/web'\n\n"
    end
    route "mount Sidekiq::Web => '/sidekiq'"
  end
end

question = 'Choose your authorization library'
choices = %w[None Pundit CanCanCan]
auth_answer = prompt.select(question, choices)

case auth_answer
when 'Pudit'
  gem 'pundit'
  after_bundle do
    run 'rails g pundit:install'
  end
when 'CanCanCan'
  gem 'cancancan'
  after_bundle do
    run 'rails g cancan:ability'
  end
end

question = 'Choose your error reporting tool'
choices = %w[None Sentry Rollbar]
monitor_answer = prompt.select(question, choices)

case monitor_answer
when 'Sentry'
  gem 'sentry-ruby'
  gem 'sentry-rails'

  initializer 'sentry.rb', <<~CODE
    Sentry.init do |config|
      config.dsn = 'https://examplePublicKey@o0.ingest.sentry.io/0'
      config.breadcrumbs_logger = [:active_support_logger, :http_logger]

      # To activate performance monitoring, set one of these options.
      # We recommend adjusting the value in production:
      config.traces_sample_rate = 1.0
      # or
      config.traces_sampler = lambda do |context|
        true
      end
    end
  CODE
when 'Rollbar'
  gem 'rollbar'
end

gem 'dry-monads'

gem_group :development do
  gem 'overcommit'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  (gem 'rubocop-graphql', require: false) if api_answer.in?(%w[GraphQL Both])
end

gem_group :development, :test do
  gem 'strong_migrations'
  gem 'rspec-rails'
  gem 'amazing_print'
  gem 'factory_bot_rails'
  gem 'pry'
  gem 'bullet'
  gem 'faker'
end

after_bundle do
  run 'rails g rspec:install'
  run 'rails g strong_migrations:install'
  run 'rails g bullet:install'

  inject_into_file 'spec/rails_helper.rb', after: 'RSpec.configure do |config|' do
    <<~CODE

      config.include FactoryBot::Syntax::Methods

      if Bullet.enable?
        config.before do
          Bullet.start_request
        end

        config.after do
          Bullet.perform_out_of_channel_notifications if Bullet.notification?
          Bullet.end_request
        end
      end
    CODE
  end

  file '.rubocop.yml', <<~CODE
    require:
      - rubocop-performance
      - rubocop-rails
      - rubocop-rspec

    AllCops:
      TargetRubyVersion: #TODO: enter ruby version
      NewCops: enable
      Exclude:
        - 'db/**/*'
        - 'vendor/**/*'
        - "tmp/**/*"
        - "bin/**/*"
        - "log/**/*"
        - "public/**/*"
        - "vendor/**/*"
    Layout/LineLength:
      Max: 120
    Style/Documentation:
      Enabled: false
    Metrics/BlockLength:
      Exclude:
        - 'config/**/*'
  CODE

  if api_answer.in?(%w[GraphQL Both])
    inject_into_file '.rubocop.yml', after: 'rubocop-rspec' do
      "\n  - rubocop-graphql"
    end
  end

  run 'rubocop -A'
  run 'git init'
  run 'git add .'
  run "git commit -m 'init'"

  puts "\n"
  puts '--------- POST GENERATION MESSAGE -----------'
  puts 'Set up your database now and run the migrations'
  puts 'Remember that most authentication tools require some mailer configuration'
end
