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
* Apache Vhosts and settings.

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

This resource defines a MySQL-Apache-WordPress instillation.


## Limitations

**THIS MODULE IS A WORK IN PROGRESS AND CURRENTLY INCOMPLETE**

This module has only been tested on CentOS 7.  There are plans to support both Debian and RedHat systems.

## Development

This module is open to collaboration and feedback.
