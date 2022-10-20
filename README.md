# puppet-graphql

This module provides a helper function to retrieve information from a GraphQL endpoint during catalog compilation.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with graphql](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module has been implemented mainly for the use-case of retrieving IP addresses from Netbox IPAM.
But it can be used for any kind of GraphQL HTTP API.

## Setup

Your puppetserver should have the _graphql-client_ gem installed.

You can install it manually by running:

```bash
puppetserver gem install graphql-client
```

You can also automate this by applying the included class `graphql::puppetserver`:

```puppet
class { 'graphql::puppetserver':
  gem_ensure           => 'present',
  puppetserver_service => 'puppetserver',
}
```

The parameters above are the defaults.

## Usage

Currently there is only a single function you can use in your puppet code:

```puppet
$query = @(EOT)
    {
      site_list {
        id,
        slug,
        name,
      }
    }
    | EOT

$result = graphql::graphql_query({
    'url'     => 'https://netbox.tld/graphql/',
    'headers' => { 'Authorization' => "Token somenetboxtoken" },
    'query'   => $query,
})

# $result could be undef in case an error occured
# the error will be logged to the puppetserver logs
if $result {
  $my_sites = $result['data']['site_list']
}


# ...
```

## Limitations

This functions in this module - as all Puppet functions - can only be executed on the puppetmaster host during 
catalog compile time.

## Development

In the Development section, tell other users the ground rules for contributing
to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

Pull requests welcome.

If you submit a change to this module, be sure to regenerate the reference documentation as follows:

```bash
puppet strings generate --format markdown --out REFERENCE.md
```
