require 'spec_helper'

describe OpsManager::DirectorTemplateGenerator do
  let!(:product_template_generator) do
    object_double(OpsManager::ProductTemplateGenerator.new('p-bosh'),
                  generate: product_template )
  end
  let(:director_template_generator){ described_class.new }
  let(:product_template) do
    {
      'products' => [
        '(( merge on identifier ))',
        { 'identifier' => 'p-bosh',
          'director_ssl' => {},
          'jobs' => [ '(( merge on identifier ))' ] }
      ]
    }
  end
  let(:installation_settings) do
    {
      'guid' => 'ab0acc994a1bc5f6f4a3',
      'infrastructure' => {},
      'ip_assignments' => '192.168.1.1',
      'installation_schema_version' => '1.7',
      'products' => [
        { 'prepared' => true,
          'identifier' => 'example_product' },
          { 'prepared' => true,
            'identifier' =>'p-bosh' }
      ]
    }
  end
  let(:director_template) do
    { 'infrastructure' => {} }.merge(product_template)
  end

  let(:installation_response) do
    double(code: 200, body: installation_settings.to_json)
  end

  before do
    allow(OpsManager::ProductTemplateGenerator)
      .to receive(:new)
      .with('p-bosh')
      .and_return(product_template_generator)
      allow_any_instance_of(OpsManager::Api::Opsman)
        .to receive(:get_installation_settings)
        .and_return(installation_response)
  end

  describe '#generate_yml' do
    it "should return template" do
      expect(director_template_generator.generate_yml).to eq(director_template.to_yaml.gsub('"',''))
    end
  end

  describe '#generate' do
    subject(:generate){ director_template_generator.generate }

    it 'should include infrastructure' do
      expect(generate['infrastructure']).to eq({})
    end

    it 'should include p-bosh product-template' do
      expect(generate['products'][1]['identifier']).to eq('p-bosh')
    end

    it 'should include product merge strategy on identifier' do
      expect(generate['products'][0]).to eq('(( merge on identifier ))')
    end

    it 'should remove installation_schema_versiion' do
      expect(generate).not_to have_key('installation_schema_version')
    end

    it 'should remove product guid' do
      expect(generate).not_to have_key('guid')
    end

    it 'should not include product director_ssl' do
      expect(generate['products'][1]).not_to have_key('director_ssl')
    end

    it 'should not include product uaa_ssl' do
      expect(generate['products'][1]).not_to have_key('uaa_ssl')
    end

    it 'should remove producty director_ssl' do
      expect(generate).not_to have_key('director_ssl')
    end

    it 'should remove ip assignments' do
      expect(generate).not_to have_key('ip_assignments')
    end

    it 'should remove guid' do
      expect(generate).not_to have_key('guid')
    end
  end
end
