require 'spec_helper'

def genpass(length); rand(36**length).to_s(36); end

describe OpsManager::ProductTemplateGenerator do
  let(:product_template_generator){ described_class.new(product_name) }
  let(:product_name){ 'dummy-product' }
  let(:guid){ 'dd2b-c21a-c11d-607d-sad1' }
  let(:installation_name){ 'example-job-123' }
  let(:random_password){ genpass(described_class::OPS_MANAGER_PASSWORD_LENGTH) }
  let(:random_secret){ genpass(described_class::OPS_MANAGER_SECRET_LENGTH) }
  let(:random_salt){ genpass(described_class::OPS_MANAGER_SALT_LENGTH) }
  let(:product_version){ '1.6.13-build.1' }
  let(:installation_settings) do
    {
      'products' => [{
        'prepared' => true, 'identifier' =>product_name, 'guid' => guid,
        'installation_name' => installation_name,
        'product_version' => product_version,
         stemcell: { 'some' => 'stemcell meta deta' },
        'properties' => [
          {
            'deployed' => false,
            'value' => {
              'private_key_pem' => 'Product Private Key'
            },
            'options' => [
              {
                'identifier' => 'internal_mysql',
                'properties' => [ { 'deployed' => false, 'identifier' => 'host' } ]
              }
            ]
          }
        ],
        'jobs' => [
          { 'identifier' => 'example-job' ,
            'guid' => 'job-guid-example' ,
            'partitions' => 'some partition info' ,
            'properties' => [
              {
                'deployed' => false,
                'value' => {
                  'identity' => 'conf-1',
                  'password' => random_password
                },
                'records' => [
                  {
                    'identifier' => 'internal_mysql',
                    'properties' => [ { 'deployed' => false, 'identifier' => 'host' } ]
                  }
                ]
              },
              {
                'value' => {
                  'identity' => 'conf-3',
                  'salt' => random_salt
                }
              },
              {
                'value' => {
                  'identity' => 'conf-4',
                  'secret' => random_secret
                }
              },
              {
                'value' => {
                  'private_key_pem' => 'Job Private Key',
                  'cert_pem' => 'Job Cert'
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
    allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_installation_settings)
      .and_return(installation_response)
  end

  describe '#generate_yml' do
    let(:generated_hash){ { "products" => [  { 'identifier' => product_name } ] } }
    let(:product_template){"---\nproducts:\n- identifier: #{product_name}\n"}

    before do
      allow(product_template_generator).to receive(:generate).and_return(generated_hash)
    end

    it "should return template" do
      expect(product_template_generator.generate_yml).to eq(product_template)
    end
  end

  describe '#generate' do
    subject(:generated_template){ product_template_generator.generate }

    it 'should remove product guid' do
      expect(generated_template.to_s).not_to match(guid)
    end

    it 'should remove product installation_name' do
      expect(generated_template.to_s).not_to match(installation_name)
    end

    it 'should remove product product_version' do
      expect(generated_template.to_s).not_to match(product_version)
    end

    it 'should remove prepared entry' do
      expect(generated_template.to_s).not_to match('prepared')
    end

    it 'should remove jobs partitions entry' do
      expect(generated_template.to_s).not_to match('some partition info')
    end

    it 'should remove jobs vm_credentials entry' do
      expect(generated_template.to_s).not_to match('some vm credentials')
    end

    it 'should remove job guid entry' do
      expect(generated_template.to_s).not_to match('job-guid-example')
    end

    it 'should remove ops_manager generated passwords' do
      expect(generated_template.to_s).not_to match(random_password)
    end

    it 'should remove automatically job properties generated salt' do
      expect(generated_template.to_s).not_to match(random_salt)
    end

    it 'should remove automatically job properties with generated secret' do
      expect(generated_template.to_s).not_to match(random_secret)
    end

    it 'should deployed flag from job properties and product properties' do
      expect(generated_template.to_s).not_to match('deployed')
    end

    it 'should should remove job properties private keys' do
      expect(generated_template.to_s).not_to match('Job Private Key')
    end

    it 'should should remove product private keys' do
      expect(generated_template.to_s).not_to match('Product Private Key')
    end

    it 'should remove the product version' do
      expect(generated_template.to_s).not_to match(product_version)
    end

    it 'should remove stemcell metadata' do
      expect(generated_template['products'].first).not_to have_key('stemcell')
    end

  end
end

