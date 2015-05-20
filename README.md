# maw

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with maw](#setup)
    * [What maw affects](#what-maw-affects)
    * [Beginning with maw](#beginning-with-maw)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Limitations - OS compatibility, etc.](#limitations)
7. [Development - Guide for contributing to the module](#development)

## Overview

**THIS MODULE IS A WORK IN PROGRESS AND CURRENTLY INCOMPLETE**

Amalgamation of MySQL, Apache, and WordPress management, creating usable WordPress sites in one go.

## Module Description

This module combines the database management of the puppetlabs-mysql module, the web server management of the puppetlabs-apache module, and custom manifest to create full stack secure WordPress sites on Debian and RedHat systems.

## Setup

### What maw affects

* MySQL databases and settings.
* Apache vhosts and settings.

### Beginning with maw

To create multiple WordPress sites pass their names as keys:

```puppet
class { 'maw':
  sites => {
    'www.my_blog.com'        => {},
    'www.my_second_blog.com' => {},
  }
}
```

## Usage

### Creating a single WordPess instance

To create a single MySQL-Apache-WordPress use the `maw::instance` resource.

```puppet
maw::instance { 'www.my_blog.com': }
```

## Reference

### Classes

#### maw

This is the base class used to define multiple maw instances.

##### `maw::sites`

Hash of all the `maw::instances` to create.

### Defined Types

#### maw::instance

This resource creates a MySQL-Apache-WordPress instance.

##### `maw::instance::domain`

  The domain name the site will have.

  Defaults to the **namevar**.

##### `maw::instance::ssl`

  Specifies if the Apache vhost should use SSL.

  Defaults to `false`.

##### `maw::instance::ssl_cert`

  The absolute file path of SSL certificate to use if `ssl` is true.

##### `maw::instance::ssl_cert_content`

  If specified, this defines the contents of the SSL certificate.

##### `maw::instance::ssl_key`

  The absolute file path of SSL key to use if `ssl` is true.

##### `maw::instance::ssl_key_content`

  If specified, this defines the contents of the SSL key.

##### `maw::instance::docroot`

  Absolute file path to the sites document root.

  Defaults to `'/var/www/${domain}'`.

##### `maw::instance::wp_version`

  Version of WordPress to install at the `docroot`.

  Valid values are the semantic version of WordPress or `'latest'` to install
  the latest version released.

  Defaults to `'latest'`.

##### `maw::instance::db_manage`

  Specifies if the MySQL database is to managed.

  Defaults to `true`.

##### `maw::instance::db_user_manage`

  Specifies if the MySQL user is to managed.

  Defaults to `true`.

##### `maw::instance::db_name`

  Name of the MySQL database to manage if `db_manage` is `true`.

  Defaults to `'wordpress'`,

##### `maw::instance::db_user`

  Name of the MySQL user to manage if `db_user_manage` is `true`.

  Defaults to `'wordpress'`,

##### `maw::instance::db_password`

  Secure password to set for the database users.

  At a minimum the password is required to be at least 8 characters long,
  but of course longer is more secure.

##### `maw::instance::db_host`

  Host address of the MySQL instance.

##### `maw::instance::manage_firewall`
  Specify if a firewall rule should be created using the puppetlabs-firewall module resource `firewall`, to allow incoming traffic to the WordPress site.

  Defaults to true.

##### `required_pkgs`

  Array of required packages for instance.

  Defaults to the OS specific php-gd package.  Any passed value should likely include php-gd as well.

## Limitations

**THIS MODULE IS A WORK IN PROGRESS AND CURRENTLY INCOMPLETE**

This module has only been tested on CentOS 7.  There are plans to support both Debian and RedHat systems.

## Development

This module is open to collaboration and feedback.
