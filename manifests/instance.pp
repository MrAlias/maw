# == Class: maw::instance
#
# Creates a MySQL-Apache-WordPress instance.
#
# This means that a MySQL database is created or checked, an Apache
# vhost is created or updated, and the correct version of WordPress
# is setup at the correct document root.
#
# It is assumed that the MySQL server and Apache web server are
# configured elsewhere.
#
# === Parameters
#
# [*domain*]
#   The domain name the site will have.
#
#   Defaults to the **namevar**.
#
# [*ssl*]
#   Specifies if the Apache Vhost should use SSL.
#
#   Defaults to `false`.
#
# [*ssl_cert*]
#   The absolute file path of SSL certificate to use if `ssl` is true.
#
# [*ssl_cert_content*]
#   If specified, this defines the contents of the SSL certificate.
#
# [*ssl_key*]
#   The absolute file path of SSL key to use if `ssl` is true.
#
# [*ssl_key_content*]
#   If specified, this defines the contents of the SSL key.
#
# [*docroot*]
#   Absolute file path to the sites document root.
#
#   Defaults to `'/var/www/${domain}'`.
#
# [*wp_version*]
#   Version of WordPress to install at the `docroot`.
#
#   Valid values are the sematic version of WordPress or `'latest'` to install
#   the latest version released.
#
#   Defaults to `'latest'`.
#
# [*db_manage*]
#   Specifies if the MySQL database is to managed.
#
#   Defaults to `true`.
#
# [*db_user_manage*]
#   Specifies if the MySQL user is to managed.
#
#   Defaults to `true`.
#
# [*db_name*]
#   Name of the MySQL database to manage if `db_manage` is `true`.
#
#   Defaults to `'wordpress'`,
#
# [*db_user*]
#   Name of the MySQL user to manage if `db_user_manage` is `true`.
#
#   Defaults to `'wordpress'`,
#
# [*db_password*]
#   Secure password to set for the database users.
#
#   At a minimum the password is required to be at least 8 characters long,
#   but of course longer is more secure.
#
# [*db_host*]
#   Host address of the MySQL instance.
#
# [*manage_firewall*]
#   Specify if a firewall rule should be created using the puppetlabs-firewall
#   module resource `firewall`, to allow incoming traffic to the WordPress
#   site.
#
#   Defaults to true.
#
# [*required_pkgs*]
#   Array of required packages for instance.
#
#   Defaults to the OS specific php-gd package.  Any passed value should
#   likely include php-gd as well.
#
# === Authors
#
# Tyler Yahn <codingalias@gmail.com>
#
define maw::instance (
  $domain           = $name,
  $ssl              = false,
  $ssl_cert         = undef,
  $ssl_cert_content = undef,
  $ssl_key          = undef,
  $ssl_key_content  = undef,
  $docroot          = undef,
  $wp_version       = 'latest',
  $db_manage        = true,
  $db_user_manage   = true,
  $db_name          = 'wordpress',
  $db_user          = 'wordpress',
  $db_password      = undef,
  $db_host          = 'localhost',
  $manage_firewall  = true,
  $required_pkgs    = hiera("${module_name}::instance::required_pkgs", undef),
) {
  validate_string($domain, $db_name, $db_user, $db_host)
  validate_array($required_pkgs)
  validate_bool($ssl, $db_manage, $db_user_manage, $manage_firewall)
  validate_re($db_password, ['', '^.{8,}$'])
  validate_re($wp_version, ['latest', '\d+\.\d+(\.\d+)?'])

  $_docroot = $docroot ? {
    undef   => "/var/www/${domain}",
    default => $docroot,
  }
  validate_absolute_path($_docroot)

  ensure_packages($required_pkgs)

  # Ensure that MySQL and Apache are setup.
  ensure_resource('class', ['mysql::server', 'apache'])

  if $db_manage {
    mysql_database { "${db_host}/${db_name}":
      ensure => present,
      name   => $db_name,
    }
  }

  if $db_user_manage {
    mysql_user { "${db_user}@${db_host}":
      ensure        => present,
      password_hash => mysql_password($db_password),
    }

    mysql_grant { "${db_user}@${db_host}/${db_name}.*":
      table      => "${db_name}.*",
      user       => "${db_user}@${db_host}",
      privileges => ['ALL'],
    }
  }

  # Ensure the SSL cert and key are correct and present.
  if $ssl {
    $port = 443

    File { ensure => file }

    if ($ssl_cert and $ssl_cert_content) {
      file { $ssl_cert:
        ensure  => file,
        content => $ssl_cert_content
      }
    }

    if $ssl_key {
      file { $ssl_key:
        ensure  => file,
        content => $ssl_key_content
      }
    }
  } else {
    $port = 80
  }

  apache::vhost { $domain:
    docroot    => $_docroot,
    port       => $port,
    ssl        => $ssl,
    ssl_cert   => $ssl_cert,
    ssl_key    => $ssl_key,
  }

  if $manage_firewall {
    $_fw = {
      chain  => 'INPUT',
      port   => $port,
      state  => 'NEW',
      proto  => 'tcp',
      action => 'accept',
    }
    ensure_resource('firewall', "300 Accept NEW TCP packets on ${port}", $_fw)
  }

  $wp_URL = $wp_version ? {
    'latest' => 'http://wordpress.org/latest.tar.gz',
    default  => "http://wordpress.org/wordpress-${wp_version}.tar.gz",
  }

  ensure_packages(['wget', 'tar'])

  exec { "Download and untar WordPress ${wp_version} for ${domain}":
    command => "wget -O - ${wp_URL} | tar zxC ${_docroot} --strip-components=1",
    creates => "${_docroot}/index.php",
    cwd     => $_docroot,
    path    => '/bin',
    require => [
      Apache::Vhost[$domain],
      Package['wget'],
      Package['tar'],
    ],
  }

  # Ensure a directory for the Apache user to upload content correctly exists.
  file { "${_docroot}/wp-content/uploads":
    ensure  => directory,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0750',
    require => Exec["Download and untar WordPress ${wp_version} for ${domain}"],
  }

  concat { "${_docroot}/wp-config.php":
    order   => 'numeric',
    require => Exec["Download and untar WordPress ${wp_version} for ${domain}"],
  }

  concat::fragment { "${_docroot}/wp-config.php header":
    content => template("${module_name}/wp-config.php_header.erb"),
    order   => '01',
    target  => "${_docroot}/wp-config.php",
  }

  concat::fragment { "${_docroot}/wp-config.php MySQL":
    content => template("${module_name}/wp-config.php_db.erb"),
    order   => '02',
    target  => "${_docroot}/wp-config.php",
  }

  concat::fragment { "${_docroot}/wp-config.php table prefix":
    content => template("${module_name}/wp-config.php_table_prefix.erb"),
    order   => '03',
    target  => "${_docroot}/wp-config.php",
  }

  $secret_key_paths = ['/etc', '/etc/puppet', '/etc/puppet/keys/']
  $secret_key_file_path = "/etc/puppet/keys/${domain}.keys"

  ensure_resource('file', $secret_key_paths, {'ensure' => 'directory'})

  file { "Secret keys for ${domain}":
    path    => $secret_key_file_path,
    ensure  => file,
    replace => false,
    content => template("${module_name}/wp-config.php_secret_keys.erb"),
    require => [
      Exec["Download and untar WordPress ${wp_version} for ${domain}"],
      File['/etc/puppet/keys/'],
    ],
  }->
  concat::fragment { "${_docroot}/wp-config.php secret keys":
    source => $secret_key_file_path,
    order  => '04',
    target => "${_docroot}/wp-config.php",
  }

  concat::fragment { "${_docroot}/wp-config.php footer":
    content => template("${module_name}/wp-config.php_footer.erb"),
    order   => '05',
    target  => "${_docroot}/wp-config.php",
  }
}
