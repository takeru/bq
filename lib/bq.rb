require "bq/version"
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'json'

module Bq
  class Base
    attr_reader :token
    attr_accessor :project_id

    def initialize(opts={})
      @project_id         = opts[:project_id]
      application_name    = opts[:application_name]    || "Bq"
      application_version = opts[:application_version] || "0.0.1"

      @client = Google::APIClient.new(
        :application_name    => application_name,
        :application_version => application_version
      )
      self.token = opts[:token] if opts[:token]
      @bq_client = @client.discovered_api('bigquery', 'v2')
    end
    def token=(token)
      @client.authorization.client_id     = token["client_id"]
      @client.authorization.client_secret = token["client_secret"]
      @client.authorization.scope         = token["scope"]
      @client.authorization.refresh_token = token["refresh_token"]
      @client.authorization.access_token  = token["access_token"]
    end
  end

  class InstalledApp < Base
    def authorize(client_secrets_json=nil)
      client_secrets_json ||= "client_secrets.json"
      puts "read from #{client_secrets_json}"
      credential = Google::APIClient::ClientSecrets.load(client_secrets_json)

      flow = Google::APIClient::InstalledAppFlow.new(
        :client_id     => credential.client_id,
        :client_secret => credential.client_secret,
        :scope         => ['https://www.googleapis.com/auth/bigquery']
      )
      @client.authorization = flow.authorize
      # Here, will be opened authorization web page.
      # Click [Authorize] button, and I see "Error: redirect_uri_mismatch".
      # But it may be succeed, authorize arguments is available.

      unless @client.authorization
        puts "failed to authorize. Canceled?"
        return nil
      end

      @token = {
        "scope"         => @client.authorization.scope,
        "client_id"     => @client.authorization.client_id,
        "client_secret" => @client.authorization.client_secret,
        "access_token"  => @client.authorization.access_token,
        "refresh_token" => @client.authorization.refresh_token
      }.freeze

      return @token
    end

    def datasets
      result = @client.execute(
        :api_method => @bq_client.datasets.list,
        :parameters => {'projectId' => @project_id}
      )
      return result.data
    end

    def query(q,timeout=90)
      result = @client.execute(
        :api_method  => @bq_client.jobs.query,
        :body_object => {
          "query"     => q,
          "timeoutMs" => timeout * 1000
        },
        :parameters => {'projectId' => @project_id}
      )
      return result.data
    end
  end
end

if __FILE__ == $0
  require "optparse"
  require "pp"

  begin
    token_file = '.bq_secret_token.json'
    opts = ARGV.getopts("",
      "authorize",            # authorize and create token file
      "client_secrets_json:", # select client_secret file
      "project_id:",          # select project id
      "datasets",             # list datasets
      "query:"                # execute query
    )
    if opts["authorize"]
      puts "will be open authorization page in web browser..."
      bq = Bq::InstalledApp.new
      bq.authorize(opts["client_secrets_json"])
      open(token_file,'w') do |f|
        JSON.dump(bq.token,f)
      end
      puts "wrote access token to file: .bq_secret_token.json"
    end

    project_id = opts["project_id"]
    raise "project_id missing." unless project_id
    token = JSON.parse File.read(token_file)
    bq = Bq::InstalledApp.new(:token=>token, :project_id=>project_id)

    if opts["datasets"]
      pp bq.datasets.to_hash
    end
    if opts["query"]
      pp bq.query(opts["query"]).to_hash
    end
  rescue => e
    p e
    puts "usage:"
    puts "  ruby bq.rb --authorize [--client_secrets_json ./client_secrets.json]"
    puts "  ruby bq.rb --project_id your-project-id --datasets"
    puts "  ruby bq.rb --project_id bq-takeru-test --query \"SELECT 123\""
  end
end
