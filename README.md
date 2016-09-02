# OpsManagerCli

Command line tool to interact with Ops Manager through its API, because GUIs are evil.

Questions? Pop in our [slack channel](https://cloudfoundry.slack.com/messages/ops_manager_cli/)!

## Core features

- Deploy/Upgrade Ops Manager appliance
- Deploy/Upgrade product tiles
- Generate config settings templates for product tiles deployments

## Other features:

- Show installation settings
- Show installation logs
- Get UAA token
- Uploads stemcell to Ops Manager
- Delete unused products

## Dependencies

 - [ovftools](https://www.vmware.com/support/developer/ovf/) (version 4.1.0 or higher)
 - [spruce](https://github.com/geofffranks/spruce#installation) 

All dependencies must be installed and available in user PATH

## installing

    gem install ops_manager

## Usage

### List available commands

    ops_manager 

### Target 

    ops_manager target OPSMAN_URL


### Login 

    ops_manager login USERNAME PASSWORD


### Deploy/Upgrade Ops Manager appliance

**config example:** [ops_manager_deployment.yml](spec/dummy/ops_manager_deployment.yml)

    ops_manager deploy ops_manager_deployment.yml


### Deploy/Upgrade product tile

**Before running:** `target` and `login`. You can do this through through config file too.

**config example:** [product_deployment.yml](spec/dummy/product_deployment.yml)

    ./ops_manager deploy-product product_deployment.yml


## Building Docker image

    bundle exec rake build
    docker build -t compozed/ops_manager_cli # Optional: --build-arg DOWNLOAD_URL=http://your_blobstore.com/ovftool.bundle


## Provisioning docker image to private registry

    docker tag -f compozed/ops_manager_cli PRI_REGISTRY:PORT/compozed/ops_manager_cli
    docker push PRI_REGISTRY:PORT/compozed/ops_manager_cli

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
