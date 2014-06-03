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
    
    bq = Bq::InstalledApp.new
    token = bq.authorize # please locate client_secrets.json in load path.
    # save token into file or db or ...
    
    bq2 = Bq::InstalledApp.new(:token=>token, :project_id=>"your-project-id")
    pp bq2.datasets.to_hash
    pp bq2.query("SELECT 12345").to_hash

## Contributing

1. Fork it ( https://github.com/takeru/bq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
