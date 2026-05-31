# frozen_string_literal: true

require 'rake_audit/adapters/base'

RSpec.describe RakeAudit::Adapters::Base do
  subject(:adapter) { described_class.new }

  describe '#save' do
    it 'raises NotImplementedError' do
      expect { adapter.save(double('record')) }
        .to raise_error(NotImplementedError, /RakeAudit::Adapters::Base#save/)
    end
  end
end
