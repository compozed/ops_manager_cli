# OpsManager

Performs Ops Manager deployments (vsphere support only).

## Pre-requisites

 - `ovftools` installed (available in user PATH) on the machine where the following process will be executed

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ops_manager'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ops_manager

## Usage

### Deploy Ops Manager

    git clone github.com/compozed/ops_manager  && cd ops_manager
    # Edit the example for the deployment that you want to perform a deployment on:
    cp spec/dummy/YOUR_CLOUD_PROVIDER.yml conf.yml && vim conf.yml

Once you have edited you configs you can run a deployment:

    ./ops_manager deploy -c conf.yml

### Provision stemcell

    ./ops_manager provision stemcell -p ./path/to/stemcell -t target -u username -p password

### Deploy product

- Upload a tile( Skip if exists)
- Enable that tile as an available product
- performs an deploy if the product was never deployed 
- performs an upgrade if the product olready exists and its old
- Apply changes if the tile already exists

    ./ops_manager deploy product -c conf.yml 

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/compozed/ops_manager. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

