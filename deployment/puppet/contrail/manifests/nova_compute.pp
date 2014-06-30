class contrail::nova_compute (
  $quantum_ip = undef,
  $vrouter_ip = undef,
  $qpid_ip = $quantum_ip,
  $glance_ip = $quantum_ip,
  $keystone_ip = $quantum_ip,
  $service_token = undef,
  $novncproxy_ip = $quantum_ip,
  $mysql_ip = $quantum_ip,
) {

  package {
    'openstack-nova-compute':
      ensure => installed;
    'contrail-nova-vif':
      ensure => installed;
  }

  file {
    # TODO zobaczyć jak sie to ma do konfiga z FUEL
    '/etc/nova/nova.conf':
      ensure  => present,
      mode    => '0640',
      owner   => root,
      group   => nova,
      require => Package['openstack-nova-compute', 'contrail-nova-vif'],
      content => template('/etc/puppet/modules/contrail/templates/nova.conf.erb');
    '/etc/contrail/ctrl-details':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => template('/etc/puppet/modules/contrail/templates/ctrl-details.erb');
    '/etc/libvirt/qemu.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      source  => 'puppet:///modules/contrail/qemu.conf';
    }

  service {
    'openstack-nova-compute':
      ensure    => running,
      enable    => true,
      subscribe => File ['/etc/nova/nova.conf'],
      require => Package['contrail-nova-vif'],
  }
}
