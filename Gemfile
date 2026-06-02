# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'rspec', '~> 3.13'
  gem 'rubocop', '~> 1.50'
end

# Exercising the Rails Engine, the TaskExecution model, the migration, and the
# install generator requires Rails and a database driver. These are test-only:
# the gem itself declares no Rails dependency and loads fine without it.
group :test do
  gem 'activerecord', '~> 7.0'
  gem 'railties', '~> 7.0'
  gem 'sqlite3', '~> 1.4'

  # The Web UI specs boot a minimal Rails application that mounts the Engine and
  # drive it over Rack. actionpack/actionview provide the controller and view
  # layers; rack-test issues the HTTP requests.
  gem 'actionpack', '~> 7.0'
  gem 'actionview', '~> 7.0'
  gem 'rack-test', '~> 2.1'
end
