require 'spec_helper'
require 'ops_manager/configs/base'

describe OpsManager::Configs::Base do
  let(:base){ described_class.new(config) }
  let(:config) do
    described_class.new(
      'filepath' => filepath
    )
  end

  describe '#filepath' do
    describe 'when filepath is a regex' do
      let(:filepath){ '*.pivotal' }

      it 'should return first mathing path' do
        expect(config.filepath).to eq('example-product-1.6.1.pivotal')
      end
    end
  end

  describe '#find_full_path' do
    describe 'when filepath is nil' do
      let(:filepath){ nil }
      before{ allow(base).to receive(:`).and_return('.') }

      it 'should return nil' do
        expect(base.find_full_path(filepath)).to be_nil
      end
    end
  end
end
