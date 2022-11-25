# frozen_string_literal: true

require 'json'

# Query a GraphQL API via HTTP.
Puppet::Functions.create_function(:"graphql::graphql_query") do
  # @param opts A Hash with the keys `url` (value `String`), `headers` (value `Hash`) and query (value `String`).
  # @return A hash containing the response data or nil when an error occurred.
  dispatch :graphql_query do
    param 'Hash[String[1], Any]', :opts
    return_type 'Optional[Hash]'
  end

  def graphql_query(opts)
    url = get_opt(opts, 'url')
    headers = get_opt(opts, 'headers')
    query = get_opt(opts, 'query')

    Puppet.info "graphql::graphql_query: Querying #{url}"

    begin
      uri = URI(url)
      request_body = { 'query' => query, 'variables' => nil }.to_json
      request_headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
      }.merge(headers)
      response = Net::HTTP.post(uri, request_body, request_headers)
      unless response.kind_of? Net::HTTPSuccess
        raise "Unexpected response code #{response.code}: #{response.body}"
      end
      JSON.parse(response.body)
    rescue => error
      puts error
      Puppet.err "graphql::graphql_query: #{error}!"
      call_function('create_resources', 'notify', { "graphql::graphql_query: #{error}!" => {} })
      nil
    end
  end

  def get_opt(opts, *path)
    opt = opts.dig(*path)
    if opt.nil?
      raise Puppet::ParseError, "Option #{path.join('.')} must be present in opts argument"
    end
    opt
  end

  def create_client(url, headers)
    http = GraphQL::Client::HTTP.new(url) do
      def headers(context)
        # rubocop:disable NestedMethodDefinition
        context[:headers]
      end
    end

    schema = GraphQL::Client.dump_schema(http, nil, context: { headers: headers })
    schema = GraphQL::Client.load_schema(schema)
    client = GraphQL::Client.new(schema: schema, execute: http)
    client.allow_dynamic_queries = true
    client
  end
end
