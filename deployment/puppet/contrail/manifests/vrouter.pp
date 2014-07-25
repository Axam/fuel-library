class contrail::vrouter (
  $discovery_server_ip      = undef,
  $control_instances_number = undef,
  $collector_ip             = undef,
  $api_ip                   = undef,
  $vrouter_ip               = undef,
  $vrouter_dec_mask         = undef,
  $vrouter_prefix           = undef,
  $vrouter_ifname           = undef,
  $vrouter_hwaddr           = undef,
  $host_ip                  = undef,  
  $gateway_ip               = undef,
  $dns                      = undef,
  $admin_user               = undef,
  $admin_pass               = undef,
  $quantum_user             = undef,
  $quantum_pass             = undef,
  $service_token            = undef,
  $quantum_ip               = undef,
  $openstack_controller_ip  = undef,
  $admin_token              = undef,
  $host_ip_list             = undef,
  $keystone_ip              = undef,
  ) {

  package {['contrail-vrouter', 'contrail-api-lib', 'python-thrift', 'contrail-setup', 'abrt', 'tunctl' , 'haproxy']:
    ensure => installed,
  }
  package {'supervisor':
    ensure  => '0.1-1.05.224.el6',
    before  => Package['contrail-vrouter'],
  }
  
  file {
    '/etc/haproxy/haproxy.cfg':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['haproxy'],
      content => template('/etc/puppet/modules/contrail/templates/haproxy.cfg.erb');
    '/etc/contrail/agent.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/agent.conf.erb');
    '/etc/contrail/agent_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [
        Package['contrail-vrouter'],
        Exec['create_python_vrouter-env','create_python_analytics-env','create_python_api-env']
      ],
      content => template('/etc/puppet/modules/contrail/templates/agent_param.erb');
    '/etc/contrail/default_pmac':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/default_pmac.erb');
    '/etc/sysconfig/network-scripts/ifcfg-vhost0':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/ifcfg-vhost0.erb');  
    '/etc/contrail/ctrl-details':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/ctrl-details.erb');
    '/etc/contrail/vrouter_nodemgr_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/vrouter_nodemgr_param.erb');
    '/etc/contrail/dns_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/dns_param.erb');
    '/etc/contrail/vnc_api_lib.ini':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-vrouter'],
      content => template('/etc/puppet/modules/contrail/templates/vnc_api_lib.ini.erb');
    "/etc/sysconfig/network-scripts/ifcfg-${vrouter_ifname}":
     ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-vrouter'],
      content => template("/etc/puppet/modules/contrail/templates/ifcfg-iface.erb");
    '/etc/modprobe.d/vrouter.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      before  => [Package['contrail-vrouter'], Package['supervisor'], Service['libvirt']],
      content => 'alias bridge off';
  }
  
  service {
    'network':
      ensure      => running,
      enable      => true,
      subscribe   => [
        File["/etc/sysconfig/network-scripts/ifcfg-${vrouter_ifname}"],
        File['/etc/sysconfig/network-scripts/ifcfg-vhost0']
        ],
      require     => Exec['create_vrouter_exec'];
    'haproxy':
      ensure      => running,
      enable      => true,
      require     => File['/etc/haproxy/haproxy.cfg'];
    'supervisor-vrouter':
      ensure      => running,
      enable      => true,
      subscribe   => [
        File['/etc/contrail/agent.conf'],
        File['/etc/contrail/agent_param'],
        File['/etc/sysconfig/network-scripts/ifcfg-vhost0']
      ],
      require     => [Exec['create_vrouter_exec'], Service['network']];
  } 
  
  firewall {
    '910 Contrail vrouter agent':
      port   => [9090,8085],
      proto  => 'tcp',
      action => 'accept';
    '911 Contrail vrouter node manager':
      port   => [8102],
      proto  => 'tcp',
      action => 'accept';
  }
  
  exec { 'create_python_vrouter-env':
     command  => "source /opt/contrail/vrouter-venv/bin/activate && /opt/contrail/vrouter-venv/bin/pip install /opt/contrail/vrouter-venv/archive/* && touch /etc/contrail/vrouter-venv.done",
     require  => Package['contrail-vrouter', 'contrail-api-lib', 'python-thrift', 'contrail-setup', 'abrt', 'tunctl','supervisor'],
     provider => 'shell',
     creates  => '/etc/contrail/vrouter-venv.done'
   }
     
  exec { 'create_python_analytics-env':
     command  => "source /opt/contrail/analytics-venv/bin/activate && /opt/contrail/analytics-venv/bin/pip install /opt/contrail/analytics-venv/archive/* && touch /etc/contrail/analytics-venv.done",
     require  => Package['contrail-vrouter', 'contrail-api-lib', 'python-thrift', 'contrail-setup', 'abrt', 'tunctl','supervisor'],
     provider => 'shell',
     creates  => '/etc/contrail/analytics-venv.done';
   }
  
  exec { 'create_python_api-env':
     command  => "source /opt/contrail/api-venv/bin/activate && /opt/contrail/api-venv/bin/pip install /opt/contrail/api-venv/archive/* && touch /etc/contrail/api-venv.done",
     require  => Package['contrail-vrouter', 'contrail-api-lib', 'python-thrift', 'contrail-setup', 'abrt', 'tunctl','supervisor'],
     provider => 'shell',
     creates  => '/etc/contrail/api-venv.done';
   }
  
  exec { 'create_vrouter_exec':
    command  => "source /opt/contrail/api-venv/bin/activate && /opt/contrail/api-venv/bin/python /opt/contrail/utils/provision_vrouter.py --host_name ${::fqdn} --host_ip ${vrouter_ip} --api_server_ip ${api_ip} --oper add --admin_user ${quantum_user} --admin_password ${quantum_pass} --admin_tenant_name services && touch /etc/contrail/run_once",
    provider => 'shell',
    creates  => '/etc/contrail/run_once',
    require  => [
      File['/etc/contrail/agent.conf'],
      File['/etc/contrail/agent_param'],
      File['/etc/sysconfig/network-scripts/ifcfg-vhost0'],
      File['/etc/contrail/vrouter_nodemgr_param'],
      Exec['create_python_api-env'],
      Exec['create_python_vrouter-env'],
      Exec['create_python_analytics-env']
    ],
  }
  
  # exec { 'rmmod_bridge':
  #    command  => 'rmmod bridge',
  #    require  => File['/etc/contrail/agent_param'],
  #    provider => 'shell',
  #  }



}
