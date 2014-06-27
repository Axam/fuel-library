# HA configuration for OpenStack Neutron
class openstack::ha::neutron {

  include 'neutron::waist_setup'

  openstack::ha::haproxy_service { 'neutron':
    order           => '085',
    listen_port     => 9696,
    public          => true,
    define_backups  => true,
    require_service => 'neutron-server',
  }

  Class['neutron'] -> Class['neutron::waistline']
  anchor {'neutron-api-up':}

  Openstack::Ha::Haproxy_service<|title == 'keystone-1' or title == 'keystone-2'|> -> Service['neutron-server']
  Openstack::Ha::Haproxy_service['neutron'] -> Class['neutron::waistline']
  Openstack::Ha::Haproxy_service['neutron'] -> Anchor['neutron-api-up']
}
