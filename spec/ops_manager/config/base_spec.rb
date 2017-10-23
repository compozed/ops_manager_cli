require 'spec_helper'
require 'byebug'
require 'ops_manager/config/base'

describe OpsManager::Config::Base do
  let!(:base){ described_class.new({filepath: filepath}) }

  describe '#expand_path_for!' do
    describe 'when filepath is a regex' do
      let(:filepath){ '*.pivotal' }

      it 'should return first mathing path' do
        expect do
          base.expand_path_for!(:filepath)
        end.to change{base[:filepath]}.to( %r{/.*/example-product-1.6.1.pivotal} )
      end
    end

    describe 'when it is an uri' do
      let(:filepath){ 'file://*.pivotal' }

      it 'should successfully expand file:// prefix values' do
        expect do
          base.expand_path_for!(:filepath)
        end.to change{base[:filepath]}.to( %r{file://.*/example-product-1.6.1.pivotal} )
      end
    end
  end


  describe '#validate_presence_of!' do
    let(:filepath){ 'tile.pivotal' }

    it 'should success when attr is present' do
      expect do
        base.validate_presence_of!(:filepath)
      end.not_to raise_error
    end

    it 'should error when attr is missing' do
      expect do
        base.validate_presence_of!(:missing_attr)
      end.to raise_error
    end
  end
end
