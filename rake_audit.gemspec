# frozen_string_literal: true

require_relative 'lib/rake_audit/version'

Gem::Specification.new do |spec|
  spec.name = 'rake_audit'
  spec.version = RakeAudit::VERSION
  spec.authors = ['Eraxel Dev']
  spec.email = ['eraxel.dev@gmail.com']

  spec.summary = 'Full audit trail for every Rake task execution.'
  spec.description = 'RakeAudit records execution history for Rake tasks ' \
                     '(timing, status, errors, environment) via a prepended ' \
                     'Rake::Task#execute hook, persisting through pluggable ' \
                     'storage adapters without altering task behavior.'
  spec.homepage = 'https://github.com/eraxel-dev/rake_audit'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('lib/**/*.rb') + %w[README.md LICENSE]
  spec.require_paths = ['lib']

  spec.add_dependency 'rake', '>= 13.0', '< 14.0'
end
