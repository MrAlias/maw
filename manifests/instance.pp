# == Class: maw::instance
#
# Creates a MySQL-Apache-WordPress instance.
#
# This means that a MySQL database is created or checked, an Apache
# vhost is created or updated, and the correct version of WordPress
# is setup at the correct doument root.
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
# [*docroot*]
#   Absolute file path to the sites document root.
#
# [*wp_version*]
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
  $docroot          = '/var/www/wordpress',
  $wp_version       = 'latest',
  $db_name          = 'wordpress',
  $db_user          = 'wordpress',
  $db_password      = undef,
  $db_host          = 'localhost',
) {
  validate_string($domain, $db_name, $db_user, $db_host)
  validate_absolute_path($docroot)
  validate_re($db_password, ['', '^.{8,}$'])
  validate_re($wp_version, ['latest', '\d+\.\d+(\.\d+)?'])

  # Ensure that MySQL and Apache are setup.
  ensure_resource('class', ['mysql::server', 'apache'])

  mysql_database { "${db_host}/${db_name}":
    name    => $db_name,
  }

  mysql_user { "${db_user}@${db_host}":
    password_hash => mysql_password($db_password),
  }

  mysql_grant { "${db_user}@${db_host}/${db_name}.*":
    table    => "${db_name}.*",
    user       => "${db_user}@${db_host}",
    privileges => ['ALL'],
  }

  # Ensure the SSL cert and key are correct and present.
  if $ssl {
    File { ensure => file }

    if $ssl_cert {
      ensure_resource('file', $ssl_cert, {'content' => $ssl_cert_content})
    }

    if $ssl_key {
      ensure_resource('file', $ssl_key, {'content' => $ssl_key_content})
    }
  }

  apache::vhost { $domain:
    docroot  => $docroot,
    ssl      => $ssl,
    ssl_cert => $ssl_cert,
    ssl_key  => $ssl_key,
  }

  $wp_URL = $wp_version ? {
    'latest' => 'http://wordpress.org/latest.tar.gz',
    default  => "http://wordpress.org/wordpress-${wp_version}.tar.gz",
  }

  ensure_package(['wget', 'tar'])

  exec { 'Download and untar WordPress':
    command => "wget -O - ${wp_URL} | tar zxC ${docroot} --strip-components=1",
    creates => "${docroot}/index.php",
    cwd     => $docroot,
    path    => '/bin',
    require => [
      Apache::Vhost[$domain],
      Package['wget'],
      Package['tar'],
    ],
  }

  # Ensure a directory to upload content correctly exists.
  file { "${docroot}/wp-content/uploads":
    ensure  => directory,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0750',
    require => Exec['Download and untar WordPress'],
  }

  file { "${domain}/wp-config.php":
    ensure  => file,
    content => template("${module_name}/wp-config.php.erb"),
    require => Exec['Download and untar WordPress'],
  }
}
