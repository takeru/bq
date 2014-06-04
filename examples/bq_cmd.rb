require "optparse"
require "pp"
require "bq"

begin
  token_file = '.bq_secret_token.json'
  opts = ARGV.getopts("",
    "authorize",            # authorize and create token file
    "client_secrets_json:", # select client_secret file
    "project_id:",          # select project id
    "datasets",             # list datasets
    "query:"                # execute query
  )
  bq = Bq::InstalledApp.new(:token_storage=>token_file)
  if opts["authorize"]
    puts "will be open authorization page in web browser..."
    bq.authorize(opts["client_secrets_json"])
    puts "wrote access token to file: #{token_file}"
  end

  project_id = opts["project_id"]
  raise "project_id missing." unless project_id
  bq.project_id = project_id

  if opts["datasets"]
    pp bq.datasets.to_hash
  end
  if opts["query"]
    pp bq.query(opts["query"]).to_hash
  end
rescue => e
  p e
  puts "usage:"
  puts "  bundle exec ruby examples/bq_cmd.rb --authorize [--client_secrets_json ./client_secrets.json]"
  puts "  bundle exec ruby examples/bq_cmd.rb --project_id your-project-id --datasets"
  puts "  bundle exec ruby examples/bq_cmd.rb --project_id your-project-id --query \"SELECT 123\""
end
