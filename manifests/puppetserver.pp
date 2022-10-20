# @summary Installs necessary dependencies for this module on the puppetserver.
#
# @example
#   include graphql::puppetserver
# @param gem_ensure The ensure parameter for the gems that will be installed.
# @param puppetserver_service The service to be restarted after a dependency has been installed or updated.
class graphql::puppetserver (
  String[1] $gem_ensure,
  String[1] $puppetserver_service,
) {
  package { 'graphql-client':
    ensure   => $gem_ensure,
    provider => 'puppetserver_gem',
    notify   => Service[$puppetserver_service],
  }
  ensure_resource('service', $puppetserver_service, { ensure => 'running', enable => true })
}
