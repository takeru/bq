# Bq

Just execute (Big)query.

## Installation

Add this line to your application's Gemfile:

    gem 'bq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bq

## Usage

    require "bq"

    # authorize and store access-token to file.
    bq = Bq::InstalledApp.new(:token_storage=>".bq_secret_token.json")
    bq.authorize # please locate client_secrets.json in load path.

    ...

    # restore access-token from file.
    bq2 = Bq::InstalledApp.new(:token_storage=>".bq_secret_token.json", :project_id=>"your-project-id")

    # execute query
    pp bq2.datasets.to_hash
    pp bq2.query("SELECT 12345").to_hash

## Example

    bq_project_id=your-project-id bundle exec ruby examples/bq_example.rb
    bundle exec ruby -rpp -e "require 'bq'; pp Bq::InstalledApp.new(:project_id=>'your-project-id',:token_storage=>'.bq_secret_token.json').query('SELECT weight_pounds, state, year, gestation_weeks FROM publicdata:samples.natality ORDER BY weight_pounds DESC LIMIT 20;').to_hash"

## Contributing

1. Fork it ( https://github.com/takeru/bq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
