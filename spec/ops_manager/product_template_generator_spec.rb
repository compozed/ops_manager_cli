require 'spec_helper'

describe OpsManager::ProductTemplateGenerator do
  let(:product_template_generator){ described_class.new(product_name) }
  let(:product_name){'dummy-product'}
  let(:guid){ 'dd2b-c21a-c11d-607d-sad1' }
  let(:installation_name){ 'example-job-123' }
  let(:random_password){ 'dd2bc21ac11d607d73c8' }
  let(:custom_password){ 'custom-password' }
  let(:random_secret){ '12341234123412341234' }
  let(:random_salt){ '1234123412341234' }
  let(:product_version){ '1.6.13-build.1' }
  let(:installation_settings) do
    {
      'products' => [{
        'prepared' => true,'identifier' =>product_name, 'guid' => guid,
        'installation_name' => installation_name,
        'product_version' => product_version,
        'properties' => [
          {
            'value' => {
              'private_key_pem' => 'Private Key'
            }
          },
          {
            'identifier' => 'product_version',
            'value' => product_version
          }
        ],
        'jobs' => [
          { 'identifier' => 'example-job' ,
            'guid' => 'job-guid-example' ,
            'partitions' => 'some partition info' ,
            'properties' => [
              {
                'value' => {
                  'identity' => 'conf-1',
                  'password' => random_password
                }
              },
              {
                'value' => {
                  'identity' => 'conf-2',
                  'password' => custom_password
                }
              },
              {
                'value' => {
                  'identity' => 'conf-1',
                  'salt' => random_salt
                }
              },
              {
                'value' => {
                  'identity' => 'conf-1',
                  'secret' => random_secret
                }
              },
              {
                'value' => {
                  'private_key_pem' => 'Private Key'
                }
              }
            ],
            'vm_credentials' => 'some vm credentials' }
        ]
      }]

    }
  end
  let(:installation_response){ double(code: 200, body: installation_settings.to_json) }

  before do
    allow(OpsManager::InstallationSettings)
      .to receive(:new).with(installation_settings)
      .and_return(installation_settings)
    allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_installation_settings)
      .and_return(installation_response)
  end

  describe '#generate_yml' do
    let(:generated_hash){ { "products" => [ "(( merge on identifier ))", { 'identifier' => product_name } ] } }
    let(:product_template){"---\nproducts:\n- (( merge on identifier ))\n- identifier: #{product_name}\n"}
    before do
      allow(product_template_generator).to receive(:generate).and_return(generated_hash)
    end

    it "should return template" do
      expect(product_template_generator.generate_yml).to eq(product_template)
    end
  end

  describe '#generate' do
    it 'should remove product guid' do
      expect(product_template_generator.generate.to_s).not_to match(guid)
    end

    it 'should remove product installation_name' do
      expect(product_template_generator.generate.to_s).not_to match(installation_name)
    end

    it 'should remove product product_version' do
      expect(product_template_generator.generate.to_s).not_to match(product_version)
    end

    it 'should remove prepared entry' do
      expect(product_template_generator.generate.to_s).not_to match('prepared')
    end

    it 'should remove jobs partitions entry' do
      expect(product_template_generator.generate.to_s).not_to match('some partition info')
    end
    it 'should remove jobs vm_credentials entry' do
      expect(product_template_generator.generate.to_s).not_to match('some vm credentials')
    end

    it 'should remove job guid entry' do
      expect(product_template_generator.generate.to_s).not_to match('job-guid-example')
    end

    it 'should remove ops_manager generated passwords' do
      expect(product_template_generator.generate.to_s).not_to match(random_password)
    end

    it 'should not remove custom passwords' do
      expect(product_template_generator.generate.to_s).to match('custom-password')
    end

    it 'should remove automatically job properties generated salt' do
      expect(product_template_generator.generate.to_s).not_to match(random_salt)
    end

    it 'should remove automatically job properties with generated secret' do
      expect(product_template_generator.generate.to_s).not_to match(random_secret)
    end

    it 'should remove job properties private keys' do
      expect(product_template_generator.generate.to_s).not_to match( 'Private Key')
    end

    it 'should remove the product version' do
      expect(product_template_generator.generate.to_s).not_to match(product_version)
    end

    it 'should remove private keys' do
      expect(product_template_generator.generate.to_s).not_to match( 'Private Key')
    end
  end
end

