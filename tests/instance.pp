maw::instance { 'www.test.site.com':
  domain           => 'mydomain.com',
  ssl              => true,
  ssl_cert         => '/etc/pki/tls/certs/dummy-cert',
  ssl_cert_content => 'test cert content',
  ssl_key          => '/etc/pki/tls/keys/dummy-key',
  ssl_key_content  => 'test key content',
  docroot          => '/var/www/test_wordpress',
  wp_version       => '4.2',
  db_name          => 'mydomain',
  db_user          => 'me',
  db_password      => 'TestingPassword',
  db_host          => '127.0.0.1',
}