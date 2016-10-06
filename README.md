# OpsManagerCli [![Build Status](https://travis-ci.org/compozed/ops_manager_cli.png?branch=master)](https://travis-ci.org/compozed/ops_manager_cli) [![Code Climate](https://codeclimate.com/github/compozed/ops_manager_cli.png)](https://codeclimate.com/github/compozed/ops_manager_cli)


Command line tool to interact with Pivotal Operations Manager through its API, because GUIs are evil.

Questions? Pop in our [slack channel](https://cloudfoundry.slack.com/messages/ops_manager_cli/)!

*Please note that the APIs of Ops Manager is experimental at this point.  Changes to the APIs with new Ops Manager releases may break functionality.*

## Features

### Core features

- Support for deploying on vSphere infrastructure
- Deploy/Upgrade Ops Manager appliance
- Deploy/Upgrade product tiles
- Generate config settings templates for product tiles deployments

### Other features:

- Show installation settings
- Show installation logs
- Get UAA token
- Uploads stemcell to Ops Manager
- Delete unused products

### Limitations:

- No support for enabling and running errands for ops_manager **< 1.7.x**


### Test with Ops Manager Version

- up to 1.8.3.0

## Upgrading OpsManager appliance from **1.7.x** to **1.8.x**

On ops_manager_cli **>=0.4.0** support for upgrading to **1.8.x** was removed.
Use ops_manager_cli **0.3.1** to upgrade from **1.7.x** -> **1.8.x**. 

## Dependencies

 - [ovftool](https://www.vmware.com/support/developer/ovf/) (version 4.1.0 or higher)
 - [spruce](https://github.com/geofffranks/spruce#installation) 

All dependencies must be installed and available in user PATH

## Installing

    gem install ops_manager_cli

## Usage

### List available commands

    ops_manager 

### Target 

    ops_manager target OPSMAN_URL


### Login 

    ops_manager login USERNAME PASSWORD


### Deploy/Upgrade Ops Manager appliance

**config example:** [ops_manager_deployment.yml](spec/dummy/ops_manager_deployment.yml)

    ops_manager deploy-appliance ops_manager_deployment.yml


### Deploy/Upgrade product tile

**Before running:** `target` and `login`. You can do this through through config file too.

**config example:** [product_deployment.yml](spec/dummy/product_deployment.yml)

    ./ops_manager deploy-product product_deployment.yml

## Using with Docker

The ops_manager_cli tool can be installed in a docker container typically in conjunction with [Concourse CI](http://concourse.ci/).  This allows users to build concourse pipelines to deploy and manage their Pivotal Cloud Foundry deployments.

### Building Docker image

    bundle exec rake build
    docker build -t compozed/ops_manager_cli # Optional: --build-arg DOWNLOAD_URL=http://your_blobstore.com/ovftool.bundle


### Provisioning docker image to private registry

    docker tag -f compozed/ops_manager_cli PRI_REGISTRY:PORT/compozed/ops_manager_cli
    docker push PRI_REGISTRY:PORT/compozed/ops_manager_cli


## Contributing

See our [CONTRUBUTING](CONTRIBUTING.md) section for more information.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
