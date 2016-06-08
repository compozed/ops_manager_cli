require 'spec_helper'

describe OpsManager::ProductTemplateGenerator do
  let(:product_template_generator){ described_class.new(product_name) }
  let(:product_name){'dummy-product'}
  let(:product_template){"---\nproducts:\n- (( merge on guid ))\n- identifier: #{product_name}\n"}
  let(:installation_settings){ {'some' => 'key', 'products' => [{ 'identifier' =>product_name }] } }
  let(:installation_response){ double(code: 200, body: installation_settings.to_json) }

  describe '#generate' do
    before do
      allow(OpsManager::InstallationSettings)
        .to receive(:new).with(installation_settings)
        .and_return(installation_settings)
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_installation_settings)
        .and_return(installation_response)
    end

    it "should return template" do
      expect(product_template_generator.generate).to eq(product_template)
    end
  end
end

