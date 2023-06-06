# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'tty-prompt'
end

prompt = TTY::Prompt.new

app_name = prompt.ask('What is the name of your application?')
app_name = prompt.ask("C'mon, give some fancy name to this nice app.") until app_name

question = 'Choose database'
choices = %w[postgresql sqlite3 mysql]
database = prompt.select(question, choices)

question = 'Choose JavaScript approach'
choices = %w[importmap webpack esbuild]
js_approach = prompt.select(question, choices)

install_css_processor = prompt.yes?('Install CSS processor?')

if install_css_processor
  question = 'Choose CSS processor. If importmap was chosen as the JavaScript approach only tailwind is compatible' \
             '(importmap is meant only for JS, you can still use other CSS frameworks, but add them separately)'
  choices = if js_approach == 'importmap'
              ['tailwind']
            else
              %w[tailwind bootstrap bulma postcss sass]
            end
  css_processor = prompt.select(question, choices)
end

skip_action_cable = prompt.yes?('Skip Action Cable?')

skip_action_text = prompt.yes?('Skip Action Text?')

skip_test_files = prompt.yes?('Skip Test Files?')

generate_command = "rails new -m ./2n_template.rb ../#{app_name} --database=#{database}"
generate_command += ' --skip-action-cable' if skip_action_cable
generate_command += ' --skip-test' if skip_test_files
generate_command += ' --skip-action-text' if skip_action_text
generate_command += " --css=#{css_processor}" if install_css_processor
generate_command += " --javascript=#{js_approach}" if js_approach

system(
  generate_command
)
