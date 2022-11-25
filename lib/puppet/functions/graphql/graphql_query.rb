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
      unless response.is_a? Net::HTTPSuccess
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
end
