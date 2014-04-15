class contrail::webui (
  $database_ip         = undef,
  $api_ip              = undef,
  $glance_ip           = undef,
  $nova_ip             = undef,
  $keystone_ip         = undef,
  $cinder_ip           = undef,
  $collector_ip        = undef,
  $master_sdn_node_ip  = undef,
  $local_sdn_node_ip   = undef,
){
  package {'contrail-openstack-webui':
    ensure => installed,
  }

  file {
    '/etc/contrail/config.global.js':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-openstack-webui'],
      content => template('/etc/puppet/modules/contrail/templates/config.global.js.erb');
    '/etc/contrail/redis-webui.conf':
      ensure  => present,
      source  => 'puppet:///modules/contrail/redis-webui.conf',
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-openstack-webui'];
  }

  service {
    'supervisor-webui':
      ensure    => running,
      enable    => true,
      require   => [
        File['/etc/contrail/config.global.js','/etc/contrail/redis-webui.conf'],
        Exec['create-python-analytics-env']
      ];
  }
  
}
