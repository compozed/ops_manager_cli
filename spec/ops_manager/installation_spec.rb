require 'spec_helper'
require 'ops_manager/installation'

describe OpsManager::Installation do
  let(:installation){ described_class.new }
  let(:trigger_response){ double(body: {'install' => {'id' =>  1 }}.to_json ) }
  let(:status_response){ double(body: {'status' => 'running' }.to_json ) }

  before do
    allow(installation).to receive(:trigger_installation).and_return(trigger_response)
    allow(installation).to receive(:get_installation).and_return(status_response)
  end

  describe '#trigger!' do
    it 'should set the installation id' do
      expect do
        installation.trigger!
      end.to change{ installation.id }
      expect(installation.id).to be_kind_of(Integer)
    end
  end

  describe '#status' do
    describe 'when installation was triggered' do
      before{ installation.trigger! }

      it 'should return the installation status' do
        expect(installation.status).not_to be_nil
      end
    end

    describe 'when installation was not trigger' do
      it 'should return nil' do
        expect(installation.status).to be_nil
      end
    end
  end
end
