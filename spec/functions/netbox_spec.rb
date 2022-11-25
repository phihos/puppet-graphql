# frozen_string_literal: true

require 'spec_helper'
require 'dry-core'
require 'netbox-client-ruby'

# start netbox via before running this test docker-compose
describe 'graphql::graphql_query' do
  netbox_host = '127.0.0.1'
  netbox_port = 8000
  netbox_rest_url = "http://#{netbox_host}:#{netbox_port}/api/"
  netbox_graphql_url = "http://#{netbox_host}:#{netbox_port}/graphql/"
  netbox_api_token = '0123456789abcdef0123456789abcdef01234567'
  list_sites_query = <<~HEREDOC
    {
      site_list {
        id,
        slug,
        name,
      }
    }
  HEREDOC

  netbox_site_name = 'Berlin'
  netbox_site_slug = 'ber'
  netbox_site_id = nil

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    wait_for_port(netbox_host, netbox_port)
    NetboxClientRuby.configure do |config|
      config.netbox.auth.token = netbox_api_token
      config.netbox.api_base_url = netbox_rest_url
    end
    sites = NetboxClientRuby.dcim.sites
    sites.each do |site|
      site.delete
    end
    new_s = NetboxClientRuby::DCIM::Site.new
    new_s.name = netbox_site_name
    new_s.slug = netbox_site_slug
    netbox_site_id = new_s.save.id
  end

  it {
    is_expected.to run.with_params({
                                     'url' => netbox_graphql_url,
                                        'headers' => { 'Authorization' => "Token #{netbox_api_token}" },
                                        'query' => list_sites_query,
                                   }).and_return({
                                                   'data' => {
                                                     'site_list' => [
                                                       {
                                                         'id' => netbox_site_id.to_s,
                                                         'slug' => netbox_site_slug,
                                                         'name' => netbox_site_name,
                                                       },
                                                     ]
                                                   }
                                                 })
  }
  it {
    is_expected.to run.with_params({
                                     'headers' => { 'Authorization' => "Token #{netbox_api_token}" },
                                        'query' => list_sites_query,
                                   }).and_raise_error(Puppet::ParseError, 'Option url must be present in opts argument')
  }
  it {
    is_expected.to run.with_params({
                                     'url' => netbox_graphql_url,
                                        'query' => list_sites_query,
                                   }).and_raise_error(Puppet::ParseError, 'Option headers must be present in opts argument')
  }
  it {
    is_expected.to run.with_params({
                                     'url' => netbox_graphql_url,
                                     'headers' => { 'Authorization' => "Token #{netbox_api_token}" },
                                   }).and_raise_error(Puppet::ParseError, 'Option query must be present in opts argument')
    is_expected.to run.with_params({
                                     # the rest url does not work with graphql
                                     # but we expect the function to nor raise an error and return nil instead
                                     'url' => netbox_rest_url,
                                     'headers' => { 'Authorization' => "Token #{netbox_api_token}" },
                                     'query' => list_sites_query,
                                   }).and_return(nil)
    expect(catalogue).to contain_notify('graphql::graphql_query: Unexpected response code 405: {"detail":"Method \"POST\" not allowed."}!')
  }
end
