require "bq/version"
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/file_storage'
require 'json'

module Bq
  class Base
    attr_accessor :project_id

    def initialize(opts={})
      @project_id         = opts[:project_id]
      application_name    = opts[:application_name]    || "Bq"
      application_version = opts[:application_version] || Bq::VERSION

      @client = Google::APIClient.new(
        :application_name    => application_name,
        :application_version => application_version
      )

      self.token_storage = opts[:token_storage] if opts[:token_storage]
      if @token_storage && @token_storage.authorization
        @client.authorization = @token_storage.authorization
      elsif opts[:token]
        @client.authorization = opts[:token]
      end

      @bq_client            = @client.discovered_api('bigquery', 'v2')
    end

    def token_storage=(storage)
      if storage.kind_of?(String)
        storage = Google::APIClient::FileStorage.new(storage)
      end
      if storage.respond_to?(:load_credentials) && storage.respond_to?(:write_credentials)
        @token_storage = storage
      else
        raise "invalid storage"
      end
    end

    def token
      @client.authorization
    end

    def authorized?
      !@client.authorization.access_token.nil?
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
      @client.authorization = flow.authorize(@token_storage)
      # Here, will be opened authorization web page.
      # Click [Authorize] button, and I see "Error: redirect_uri_mismatch".
      # But it may be succeed, authorize arguments is available.

      unless @client.authorization
        puts "failed to authorize. Canceled?"
        return false
      end

      return true
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
    puts "  ruby bq.rb --authorize [--client_secrets_json ./client_secrets.json]"
    puts "  ruby bq.rb --project_id your-project-id --datasets"
    puts "  ruby bq.rb --project_id bq-takeru-test --query \"SELECT 123\""
  end
end
