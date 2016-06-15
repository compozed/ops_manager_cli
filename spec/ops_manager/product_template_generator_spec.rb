require 'spec_helper'

describe OpsManager::ProductTemplateGenerator do
  let(:product_template_generator){ described_class.new(product_name) }
  let(:product_name){'dummy-product'}
  let(:product_template){"---\nproducts:\n- (( merge on guid ))\n- identifier: #{product_name}\n  jobs:\n  - (( merge on identifier ))\n"}
  let(:installation_settings){ { 'products' => [{ 'prepared' => true,'identifier' =>product_name, 'jobs' => [] }] } }
  let(:installation_response){ double(code: 200, body: installation_settings.to_json) }

    before do
      allow(OpsManager::InstallationSettings)
        .to receive(:new).with(installation_settings)
        .and_return(installation_settings)
      allow_any_instance_of(OpsManager::Api::Opsman).to receive(:get_installation_settings)
        .and_return(installation_response)
    end

  describe '#generate_yml' do
    it "should return template" do
      expect(product_template_generator.generate_yml).to eq(product_template)
    end
  end

  describe '#generate' do
    it 'should remove prepared entry' do
      expect(product_template_generator.generate.to_s).not_to match('prepared')
    end

    describe 'when products have partitions' do
      let(:installation_settings)  do
        { 'prepared' =>  true , 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [
              { 'identifier' => 'example-job' ,
                'partitions' => 'some partition info' }
          ]
        }
        ]
        }
      end

      it 'should remove partitions entry' do
        expect(product_template_generator.generate.to_s).not_to match('some partition info')
      end
    end

    describe 'when products have vm_credentials' do
      let(:installation_settings)  do
        { 'prepared' =>  true , 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [
              { 'identifier' => 'example-job' ,
                'vm_credentials' => 'some vm credentials' }
          ]
        }
        ]
        }
      end

      it 'should remove vm_credentials entry' do
        expect(product_template_generator.generate.to_s).not_to match('some vm credentials')
      end
    end

    describe 'when products have guid' do
      let(:installation_settings)  do
        { 'prepared' =>  true , 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [
              { 'identifier' => 'example-job' ,
                'guid' => 'job-guid-example' }
          ]
        }
        ]
        }
      end

      it 'should remove guid entry' do
        expect(product_template_generator.generate.to_s).not_to match('job-guid-example')
      end
    end

    describe 'when product job properties has passwords' do
      let(:random_password){ 'dd2bc21ac11d607d73c8' }
      let(:custom_password){ 'custom-password' }
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [
              { 'identifier' => 'example-job' ,
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
                  }
              ]
          }
          ]
        }
        ]}
      end

      it 'should remove ops_manager generated passwords' do
        expect(product_template_generator.generate.to_s).not_to match(random_password)
      end

      it 'should not remove custom passwords' do
        expect(product_template_generator.generate.to_s).to match('custom-password')
      end
    end

    describe 'when product job properties has salt' do
      let(:random_salt){ '1234123412341234' }
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [
              { 'identifier' => 'example-job' ,
                'properties' => [
                  {
                    'value' => {
                      'identity' => 'conf-1',
                      'salt' => random_salt
                    }
                  }
              ]
          }
          ]
        }
        ]}
      end

      it 'should remove automatically generated salt' do
        expect(product_template_generator.generate.to_s).not_to match(random_salt)
      end
    end

    describe 'when product job properties has secret' do
      let(:random_secret){ '12341234123412341234' }
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [ { 'identifier' => 'example-job',
                          'properties' => [
                            {
                              'value' => {
                                'identity' => 'conf-1',
                                'secret' => random_secret
                              }
                            }
            ]

        } ]
        }
        ]}
      end

      it 'should remove automatically generated secret' do
        expect(product_template_generator.generate.to_s).not_to match(random_secret)
      end
    end

    describe 'when product properties has secret' do
      let(:random_secret){ '12341234123412341234' }
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'properties' => [
              {
                'value' => {
                  'identity' => 'conf-1',
                  'secret' => random_secret
                }
              }
          ],
          'jobs' => [ { 'identifier' => 'example-job' } ]
        }
        ]}
      end

      it 'should remove automatically generated secret' do
        expect(product_template_generator.generate.to_s).not_to match(random_secret)
      end
    end

    describe 'when product properties has secret private_key_pem' do
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'properties' => [
              {
                'value' => {
                  'private_key_pem' => 'Private Key'
                }
              }
          ],
          'jobs' => [ { 'identifier' => 'example-job' } ]
        }
        ]}
      end

      it 'should remove private keys' do
        expect(product_template_generator.generate.to_s).not_to match( 'Private Key')
      end
    end

    describe 'when product job properties has private_key_pem' do
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [ {
            'identifier' => 'example-job' ,
            'properties' => [{
              'value' => {
                'private_key_pem' => 'Private Key'
              }
            }]
          }]
        }
        ]}
      end

      it 'should remove private keys' do
        expect(product_template_generator.generate.to_s).not_to match( 'Private Key')
      end
    end

    describe 'when product version is present' do
      let(:product_version){ '1.6.13-build.1' }
      let(:installation_settings)  do
        { 'products' => [
          { 'identifier' => product_name ,
            'jobs' => [ ],
            'properties' => [
              {
                'identifier' => 'product_version',
                'value' => product_version
              }
            ]
        }
        ]
        }
      end

      it 'should remove the version value' do
        expect(product_template_generator.generate.to_s).not_to match(product_version)
      end
    end
  end
end

