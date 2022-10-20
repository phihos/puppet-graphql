# frozen_string_literal: true

begin
  require 'graphql/client'
  require 'graphql/client/http'
rescue LoadError => _
  Puppet.info "You need to install the 'graphql-client' gem. Try 'puppetserver gem install graphql-client'."
end

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

    begin
      client = create_client(url, headers)
      query = client.parse(query)
      result = client.query(query, context: { headers: headers })
      result.to_h
    rescue => error
      puts "graphql::graphql_query: #{error}!"
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
      def headers(context) # rubocop:disable NestedMethodDefinition
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
