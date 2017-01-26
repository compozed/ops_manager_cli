require 'spec_helper'
require 'ops_manager/logging'

describe OpsManager::Logging do
  class Foo; include OpsManager::Logging; end

  describe 'Foo#logger' do
    let(:foo){ Foo.new }

    before do
      OpsManager::Logging.logger=nil
    end

    it 'should be kind of Logger' do
      expect(foo.logger).to be_kind_of(Logger)
    end

    it 'should always return the same instance' do
      expect(foo.logger).to eq(foo.logger)
    end

    it 'should output logs to stdout' do
      expect(Logger).to receive(:new).with(STDOUT).and_call_original
      foo.logger
    end

    it 'should log in WARN level' do
      expect_any_instance_of(Logger).to receive(:level=).with(Logger::WARN)
      foo.logger
    end

    describe 'when DEBUG' do
      before { ENV['DEBUG']= 'true' }

      it 'should log in INFO level' do
        expect_any_instance_of(Logger).to receive(:level=).with(Logger::INFO)
        foo.logger
      end

      after{ ENV.delete('DEBUG') }
    end
  end
end
