class contrail::quantum (
  $neutron_config      = {},
  $rabbit_user         = undef,
  $rabbit_password     = undef,
  $rabbit_hosts        = undef,
  $auth_host           = '127.0.0.1',
  $auth_port           = 35357,
  $auth_protocol       = 'http',
  $admin_tenant_name   = 'services',
  $admin_user          = 'neutron',
  $admin_password      = 'neutron',
  $bind_port           = 9696,
  $bind_host           = '0.0.0.0',
  $api_ip              = undef,
  $sdn_controllers     = $quantum_config['contrail']['sdn_controllers'],
  $internal_virtual_ip = $::fuel_settings['management_vip'],
  $public_virtual_ip   = $::fuel_settings['public_vip'],

){
  
  package {
    ['openstack-neutron-contrail', 'openstack-neutron']:
      ensure => '2013.2-1.05.215m1';
    ['contrail-api-lib', 'python-django-compressor', 'python-django-openstack-auth']:
      ensure => present;
#     'openstack-dashboard':
#       ensure => '2012.1-243';
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
   '/usr/share/openstack-dashboard/openstack_dashboard/local/local_settings.py':
      force   => true,
      ensure  => 'link',
      target  => '/etc/openstack-dashboard/local_settings',
      require => [Package['openstack-dashboard'], Exec['contrail-dashboard'],File['/etc/openstack-dashboard/local_settings']],
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
    '/etc/haproxy/conf.d/990-contrail.cfg':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => File['/etc/haproxy/conf.d'],
      content => template('/etc/puppet/modules/contrail/templates/haproxy-neutron.erb');
  }
  
  file_line { 'local_settings':
    path    => '/etc/openstack-dashboard/local_settings',
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
  
  Neutron_config {
    require => Package['openstack-neutron'],
    notify => Service['neutron-server']
  }
  Contrail_plugin_ini_config {
    require => Package['openstack-neutron-contrail'],
    notify => Service['neutron-server']
  }

  if $::fuel_settings['deployment_mode'] == 'multinode' {
    neutron_config {
     'DEFAULT/rpc_backend':                  value => 'neutron.openstack.common.rpc.impl_kombu';
     'DEFAULT/rabbit_userid':                value => $rabbit_user;
     'DEFAULT/rabbit_password':              value => $rabbit_password;
     'DEFAULT/rabbit_hosts':                 value => $rabbit_hosts;
     'DEFAULT/bind_host':                    value => $bind_host;
     'DEFAULT/bind_port':                    value => $bind_port;
     'DEFAULT/core_plugin':                  value => 'neutron.plugins.juniper.contrail.contrailplugin.ContrailPlugin';
     'keystone_authtoken/auth_host':         value => $auth_host;
     'keystone_authtoken/auth_port':         value => $auth_port;
     'keystone_authtoken/auth_protocol':     value => $auth_protocol;
     'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
     'keystone_authtoken/admin_user':        value => $admin_user;
     'keystone_authtoken/admin_password':    value => $admin_password;
     'QUOTAS/quota_network':                 value => '-1';
     'QUOTAS/quota_subnet':                  value => '-1';
     'QUOTAS/quota_port':                    value => '-1';
     'APISERVER/api_server_ip':              value => $quantum_config['contrail']['api_ip'];
     'APISERVER/api_server_port':            value => '8082';
     'APISERVER/multi_tenancy':              value => 'True';
    }
  }
  else {
    neutron_config {
     'DEFAULT/rpc_backend':                  value => 'neutron.openstack.common.rpc.impl_kombu';
     'DEFAULT/rabbit_userid':                value => $rabbit_user;
     'DEFAULT/rabbit_password':              value => $rabbit_password;
     'DEFAULT/rabbit_hosts':                 value => $rabbit_hosts;
     'DEFAULT/bind_host':                    value => $bind_host;
     'DEFAULT/bind_port':                    value => $bind_port;
     'DEFAULT/core_plugin':                  value => 'neutron.plugins.juniper.contrail.contrailplugin.ContrailPlugin';
     'keystone_authtoken/auth_host':         value => $auth_host;
     'keystone_authtoken/auth_port':         value => $auth_port;
     'keystone_authtoken/auth_protocol':     value => $auth_protocol;
     'keystone_authtoken/admin_tenant_name': value => $admin_tenant_name;
     'keystone_authtoken/admin_user':        value => $admin_user;
     'keystone_authtoken/admin_password':    value => $admin_password;
     'QUOTAS/quota_network':                 value => '-1';
     'QUOTAS/quota_subnet':                  value => '-1';
     'QUOTAS/quota_port':                    value => '-1';
     'APISERVER/api_server_ip':              value => $::fuel_settings['management_vip'];
     'APISERVER/api_server_port':            value => '8082';
     'APISERVER/multi_tenancy':              value => 'True';
    }
  }
  
  contrail_plugin_ini_config {
    'APISERVER/api_server_ip':             value => $api_ip;
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
#    require     => Exec['config-neutron-apiserver'];
    require     => Exec['enable_forwarding','save_ipv4_forward'];
  }

  exec { 'contrail-dashboard':
    command  => "yum downgrade -d 0 -e 0 -y openstack-dashboard-2013.2-1.05.215m1",
    require  => Package['dashboard'],
    before   => File['/etc/openstack-dashboard/local_settings'],
    path     => '/usr/bin',
  }

  exec { 'enable_forwarding':
    path => '/usr/bin:/bin:/usr/sbin:/sbin',
    command => 'echo 1 > /proc/sys/net/ipv4/ip_forward',
    unless  => 'cat /proc/sys/net/ipv4/ip_forward | grep -q 1',
  }
  exec { 'save_ipv4_forward':
    path => '/usr/bin:/bin:/usr/sbin:/sbin',
    command => 'sed -i --follow-symlinks -e "/net\.ipv4\.ip_forward/d" \
                   /etc/sysctl.conf && echo "net.ipv4.ip_forward = 1" >> \
                   /etc/sysctl.conf',
    unless  => 'grep -q "^\s*net\.ipv4\.ip_forward = 1" /etc/sysctl.conf',
  }

#  exec { 'config-neutron-apiserver':
#    notify   => Service['neutron-server'],
#    command  => "/usr/bin/openstack-config --set /etc/neutron/neutron.conf APISERVER api_server_ip $api_ip && /usr/bin/openstack-config --set /etc/neutron/neutron.conf APISERVER api_server_port 8082 && /usr/bin/openstack-config --set /etc/neutron/neutron.conf APISERVER multi_tenancy True",
#    provider => 'shell',
#    path     => '/bin',
#  }

  
  # exec { 'contrail-api-lib':
  #   command  => "yum install -d 0 -e 0 -y contrail-api-lib-1.02-243.el6.noarch",
  #   path     => '/usr/bin',
  #   require  => Package['rabbitmq-server'],
  # } 

}