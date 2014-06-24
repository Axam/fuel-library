class nova::objectstore(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

  file {
    '/etc/init.d/openstack-nova-objectstore':
      ensure  => present,
      source  => 'puppet:///modules/nova/openstack-nova-objectstore',
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
  }

  nova::generic_service { 'objectstore':
    enabled        => $enabled,
    package_name   => $::nova::params::objectstore_package_name,
    service_name   => $::nova::params::objectstore_service_name,
    ensure_package => $ensure_package,
  }

}
