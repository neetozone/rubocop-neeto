# RuboCop::Neeto

## Cops

1. [Neeto/UnsafeTableDeletion](https://rubocop-neeto.neetodeployapp.com/docs/RuboCop/Cop/Neeto/UnsafeTableDeletion)
2. [Neeto/UnsafeColumnDeletion](https://rubocop-neeto.neetodeployapp.com/docs/RuboCop/Cop/Neeto/UnsafeColumnDeletion)

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rubocop-neeto

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rubocop-neeto

## Usage

Add the following line to your `.rubocop.yml` file.

```yaml
require: rubocop-neeto
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
require:
  - rubocop-other-extension
  - rubocop-neeto
```

Now, run the `rubocop` command ti load `rubocop-neeto` cops together with the
standard cops.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
