# OpsManagerDeployer

Performs Ops Manager deployments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ops_manager_deployer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ops_manager_deployer

## Usage

    git clone github.com/compozed/ops_manager_deployer  && cd ops_manager_deployer
    # Edit the example for the cloud that you want to perform a deployment on:
    cp spec/dummy/YOUR_CLOUD_PROVIDER.yml conf.yml && vim conf.yml

Once you have edited you configs you can run a deployment:

    ops_manager_deployer conf.yml


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/compozed/ops_manager_deployer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

