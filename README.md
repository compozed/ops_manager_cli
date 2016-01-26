# OpsManager

Performs Ops Manager deployments (vsphere support only).

## Pre-requisites

 - `ovftools` (version 4.1.0 or higher) installed (available in user PATH) on your workstation

## Installation

**NOTE: this installation process will only work once the gem gets publish and open source.**

Add this line to your application's Gemfile:

    gem 'ops_manager'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ops_manager

## Usage

### Help

prints out available commands with their usage

    ./ops_manager help

### Deploy or upgrade Ops Manager

It does not require **target** or **login**.

Once you have created the config you can run a deployment:

    ./ops_manager deploy [config/ops_manager_example.yml](spec/dummy/ops_manager_deployment.yml)


### Target OpsManager

    ./ops_manager target ops_manager_address


### Login in to OpsManager

    ./ops_manager login username password


### Upgrade a product

Remember to perform  **target** and **login** before performing an upgrade

    ./ops_manager deploy-product [config/product_example.yml](spec/dummy/ops_manager_deployment.yml)


### Provision stemcell(TBD)

    ./ops_manager provision stemcell -p ./path/to/stemcell 


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/compozed/ops_manager. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

