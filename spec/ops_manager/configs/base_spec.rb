require 'spec_helper'
require 'ops_manager/configs/base'

describe OpsManager::Configs::Base do
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
end
