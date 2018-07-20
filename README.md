# Pivotality analysis for electricity markets

Allow to calculate the hourly residual demand (and then the absolute indispensability) of a electricity producer (here called 'operator') in a given zone set and a whole year.

## The domain



## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pivotality'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pivotality


## Usage

Initialize a piv object passing the year as parameter:
```ruby
piv = Piv.new(2014)
```
Because the calculation will be related to hourly data over a full year you will need to pass arrays of size 8760 (or 8784 in case of a leap year).

Then load all data required for calculation, for each zone or area:
- Energy and Power requests
- imports from abroad
- transmission constraints (limits) from adjacent zones
- production capacity of a given productor
- production capacity of competitors of a given productor

in this way:
```ruby
piv.add_energy_req(
  z1 => [234.0, 230.0, ..., 188.3], # 8760 values
  z2 => ...
)
piv.add_power_req(
  z1 => [...], # 8760 values
  z2 => ...
)
piv.add_imports( # imports to...
  z1 => [...], # 8760 values
  z2 => ...
)

piv.add_limits(
  z1 => {
    z2 => [...], # from z2 to z1
    z3 => ...
  }
  z2 => ...
)
piv.add_operator_production(op1,
  z1 => [...],
  z2 => ...
)
piv.add_competitors_production(op1,
  z1 => [...],
  z2 => ...
)

```




## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pivotality. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pivotality project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pivotality/blob/master/CODE_OF_CONDUCT.md).
