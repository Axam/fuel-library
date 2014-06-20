class contrail::quantum (
  $quantum_config    = {},
  $rabbit_user       = undef,
  $rabbit_password   = undef,
  $rabbit_hosts      = undef,
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $admin_tenant_name = 'services',
  $admin_user        = 'quantum',
  $admin_password    = 'quantum',
  $bind_port         = 9696,
  $bind_host         = '0.0.0.0',
){
  
  package {
    ['openstack-neutron-contrail', 'openstack-neutron']:
      ensure => '2013.2-1.05.215m1';
    ['contrail-api-lib', 'python-django-compressor', 'python-django-openstack-auth']:
      ensure => present;
    # 'openstack-dashboard':
    #   ensure => '2012.1-243';
    'python-neutronclient':
      ensure => '2.3.0-11.05.215m1';
    # 'nodejs':  
    #   ensure => '0.10.4-1.el6';
  }
  
  file {
    '/usr/bin/nodejs':
      ensure  => 'link',
      target  => '/usr/bin/node',
      require => Package['openstack-dashboard', 'nodejs', 'python-neutronclient'],
      notify  => Service['httpd'];
   '/usr/lib/python2.6/site-packages/openstack_dashboard/local/local_settings.py':
      force   => true,
      ensure  => 'link',
      target  => '/etc/openstack_dashboard/local_settings',
      require => [Package['openstack-dashboard'], Exec['contrail-dashboard'], File['/etc/openstack_dashboard/local_settings']],
      notify  => Service['httpd'];
    '/etc/contrail':
      ensure  => directory,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['openstack-neutron'];
    '/etc/contrail/vnc_api_lib.ini':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => File['/etc/contrail'],
      content => template('/etc/puppet/modules/contrail/templates/vnc_api_lib.ini-quantum.erb');
  }
  
  file_line { 'local_settings':
    path    => '/etc/openstack_dashboard/local_settings',
    require => Exec['contrail-dashboard'],
    line    => 'COMPRESS_ENABLED = False',
    notify  => Service['httpd'];
   }
  
  # file { 
  #   '/etc/quantum/plugins/contrail/contrail_plugin.ini':
  #    ensure  => present,
  #    mode    => '0644',
  #    owner   => root,
  #    group   => root,
  #    # content => template('/etc/puppet/modules/contrail/templates/contrail_plugin.ini.erb'),
  #    require => Package['openstack-quantum-contrail'];
  #   '/etc/quantum/quantum.conf':
  #    ensure  => present,
  #    mode    => '0644',
  #    owner   => root,
  #    group   => root,
  #    # content => template('/etc/puppet/modules/contrail/templates/quantum.conf.erb'),
  #    require => Package['openstack-quantum-contrail'];
  # }
  
  Quantum_config {
    require => Package['openstack-neutron'],
    notify => Service['neutron-server']
  }
  Contrail_plugin_ini_config {
    require => Package['openstack-neutron-contrail'],
    notify => Service['neutron-server']
  }
  
  quantum_config {
   'DEFAULT/rpc_backend':                  value => 'neutron.openstack.common.rpc.impl_kombu';
   'DEFAULT/rabbit_userid':                value => $rabbit_user;
   'DEFAULT/rabbit_password':              value => $rabbit_password;
   'DEFAULT/rabbit_hosts':                 value => $rabbit_hosts;
   'DEFAULT/bind_host':                    value => $bind_host;
   'DEFAULT/bind_port':                    value => $bind_port;
   'DEFAULT/core_plugin':                  value => 'neutron.plugins.contrail.ContrailPlugin.ContrailPlugin';
   'keystone_authtoken/auth_host':         value => $auth_host;
   'keystone_authtoken/auth_port':         value => $auth_port;
   'keystone_authtoken/auth_protocol':     value => $auth_protocol;
   'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
   'keystone_authtoken/admin_user':        value => $admin_user;
   'keystone_authtoken/admin_password':    value => $admin_password;
   'QUOTAS/quota_network':                 value => '-1';
   'QUOTAS/quota_subnet':                  value => '-1';
   'QUOTAS/quota_port':                    value => '-1';
  }
  
  contrail_plugin_ini_config {
    'APISERVER/api_server_ip':             value => $quantum_config['contrail']['api_ip'];
    'APISERVER/api_server_port':           value => '8082';
    'APISERVER/multi_tenancy':             value => 'True';
    'KEYSTONE/admin_user':                 value => $admin_user;
    'KEYSTONE/admin_password':             value => $admin_password;
    'KEYSTONE/admin_tenant_name':          value => $admin_tenant_name;
    #todo: add keystone IP/url
  }

  service { 'neutron-server':
    ensure      => running,
    enable      => true,
  }

  exec { 'contrail-dashboard':
    command  => "yum downgrade -d 0 -e 0 -y openstack-dashboard-2013.2-1.05.215m1.noarch",
    require  => Package['dashboard'],
    before   => File['/etc/openstack_dashboard/local_settings'],
    path     => '/usr/bin',
  }
  
  # exec { 'contrail-api-lib':
  #   command  => "yum install -d 0 -e 0 -y contrail-api-lib-1.02-243.el6.noarch",
  #   path     => '/usr/bin',
  #   require  => Package['rabbitmq-server'],
  # } 

}