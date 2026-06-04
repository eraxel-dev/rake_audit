# frozen_string_literal: true

# Standard Rails base model. rake_audit's RakeAudit::TaskExecution inherits from
# ApplicationRecord when the host app defines it (as here), picking up this
# app's database connection and conventions.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
