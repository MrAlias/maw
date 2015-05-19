# == Class: maw
#
# Handles the creation of `maw::instance`(s).
#
# === Parameters
#
# [*sites*]
#   Hash of the `maw::instance`(s) to create.
#
# === Examples
#
#  class { 'maw':
#    sites => {
#      'www.my_blog.com'        => {},
#      'www.my_second_blog.com' => {},
#    }
#  }
#
# === Authors
#
# Tyler Yahn <codingalias@gmail.com>
#
class maw (
  $sites = hiera("${module_name}::sites", undef),
) {
  create_resources(maw::instance, $sites)
}
