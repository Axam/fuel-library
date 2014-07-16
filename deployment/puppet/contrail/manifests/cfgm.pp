class contrail::cfgm (
  $service_token           = undef,
  $admin_token             = undef,
  $openstack_controller_ip = undef,
  $quantum_ip              = undef,
  $admin_user              = undef,
  $admin_pass              = undef,
  $quantum_user            = undef,
  $quantum_pass            = undef,
  $rabbit_user             = undef,
  $rabbit_password         = undef,
  $rabbit_hosts            = undef,
  $keystone_ip             = undef,
  $api_ip                  = undef,
  $ifmap_ip                = undef,
  $discovery_server_ip     = undef,
  $cassandra_ip            = undef,
  $collector_ip            = undef,
  $zookeeper_ip            = undef,
  $sdn_controllers         = undef,
  $deployment_mode         = undef,
  $redis_ip                = undef,
  $host_ip                 = undef,
  $keystone_admin_token    = $::fuel_settings['keystone']['admin_token'],
  ){

  package {
    'python-novaclient':
      ensure => '2.16.0-2.el6';
    'python-keystoneclient':
      ensure => '0.4.1-4.el6';
    'python-neutronclient':
      ensure => '2.3.0-11.05.215m1';
    'contrail-api-lib':
      ensure => installed;
    'contrail-api-extension':
      ensure => installed;
    'contrail-config':
      ensure => installed;
    'contrail-setup':
      ensure => installed;
    'python-psutil':
      ensure => installed;
    'euca2ools':
      ensure => installed;
    'm2crypto':
      ensure => installed;
    'rabbitmq-server':
      ensure => installed;
    'haproxy':
      ensure => installed;
    'zookeeper':
      ensure => installed;
    }

  file {
    '/var/lib/zookeeper/myid':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['supervisor'],
      content => template('/etc/puppet/modules/contrail/templates/myid.erb');
    '/etc/contrail/supervisord_config_files/contrail-api.ini':
      ensure  => present,
      mode    => '0755',
      owner   => root,
      group   => root,
      require => [
        Package['supervisor', 'rabbitmq-server'],
        Service['rabbitmq-server']
      ],
      content => template('/etc/puppet/modules/contrail/templates/contrail-api.ini.erb');
    '/etc/contrail/supervisord_config_files/contrail-discovery.ini':
      ensure  => present,
      mode    => '0755',
      owner   => root,
      group   => root,
      require => Package['supervisor'],
      content => template('/etc/puppet/modules/contrail/templates/contrail-discovery.ini.erb');
    '/etc/haproxy/haproxy.cfg':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['haproxy'],
      content => template('/etc/puppet/modules/contrail/templates/haproxy-ctrl.cfg.erb');
    '/etc/contrail/ctrl-details':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [
        Package['contrail-config','python-novaclient','python-keystoneclient','python-neutronclient'],
        Exec['create-python-analytics-env']
       ],
      content => template('/etc/puppet/modules/contrail/templates/ctrl-details-cfgm.erb');
    '/etc/contrail/api_server.conf':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => [
        Package['contrail-config', 'rabbitmq-server'],
        Service['rabbitmq-server'], 
        Exec['create-python-api-env']
      ],
      content => template('/etc/puppet/modules/contrail/templates/api_server.conf.erb');
    '/etc/contrail/vnc_api_lib.ini':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/vnc_api_lib.ini.erb');
    '/etc/contrail/schema_transformer.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/schema_transformer.conf.erb');
    '/etc/contrail/svc_monitor.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/svc_monitor.conf.erb');
    '/etc/contrail/discovery.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [
        Package['contrail-config'],
        Exec['create-python-control-env']
       ],
      content => template('/etc/puppet/modules/contrail/templates/discovery.conf.erb');
    '/etc/contrail/redis_config.conf':
      ensure  => present,
      source  => 'puppet:///modules/contrail/redis_config.conf',
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'];
    '/etc/contrail/redis-uve.conf':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/redis-uve.conf.erb');
    '/etc/zookeeper/zoo.cfg':
      notify  => Service['zookeeper'],
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/zoo.cfg.erb');
    # '/etc/qpidd.conf':
    #   ensure  => present,
    #   source  => 'puppet:///modules/contrail/qpidd.conf',
    #   mode    => '0644',
    #   owner   => 'root',
    #   group   => 'root',
    #   require => Package['contrail-config'];
    '/etc/irond/basicauthusers.properties':
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'],
      content => template('/etc/puppet/modules/contrail/templates/basicauthusers.properties.erb');
    # '/etc/init.d/zookeeper':
    #   ensure  => present,
    #   source  => 'puppet:///modules/contrail/zookeeper',
    #   mode    => '0775',
    #   owner   => 'root',
    #   group   => 'hadoop',
    #   require => Package['contrail-config'];
    '/etc/zookeeper/zookeeper-env.sh':
      ensure  => present,
      source  => 'puppet:///modules/contrail/zookeeper-env.sh',
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'];
    '/etc/zookeeper/log4j.properties':
      ensure  => present,
      source  => 'puppet:///modules/contrail/log4j.properties',
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'];  
    '/etc/init.d/contrail-api':
      ensure  => present,
      source  => 'puppet:///modules/contrail/contrail-api',
      mode    => '0731',
      owner   => 'root',
      group   => 'root',
      require => [
        Package['contrail-config', 'rabbitmq-server'],
        Service['rabbitmq-server']
      ];
    '/etc/init.d/contrail-discovery':
      ensure  => present,
      source  => 'puppet:///modules/contrail/contrail-discovery',
      mode    => '0731',
      owner   => 'root',
      group   => 'root',
      require => Package['contrail-config'];      
  }
  service {
    'supervisor-config':
      ensure      => running,
      enable      => true,
      notify      => Service['supervisor-control'],
      require     =>  [
        File['/etc/irond/basicauthusers.properties','/etc/contrail/redis_config.conf','/etc/contrail/redis-uve.conf','/etc/contrail/discovery.conf','/etc/contrail/api_server.conf','/etc/contrail/schema_transformer.conf','/etc/contrail/supervisord_config_files/contrail-api.ini','/etc/contrail/supervisord_config_files/contrail-discovery.ini','/var/lib/zookeeper/myid','/etc/contrail/ctrl-details'],
        Service['contrail-named','contrail-dns'],
        ],
      subscribe   => [
        File['/etc/irond/basicauthusers.properties','/etc/contrail/redis_config.conf','/etc/contrail/redis-uve.conf','/etc/contrail/discovery.conf','/etc/contrail/api_server.conf','/etc/contrail/schema_transformer.conf','/etc/contrail/supervisord_config_files/contrail-api.ini','/etc/contrail/supervisord_config_files/contrail-discovery.ini','/var/lib/zookeeper/myid','/etc/contrail/ctrl-details'],
        Exec['create-python-api-env']
        ];
    'rabbitmq-server':
      ensure      => running,
      enable      => true,
      require => Package["rabbitmq-server"];
    'haproxy':
      ensure      => running,
      enable      => true,
      require     => [
        File['/etc/haproxy/haproxy.cfg'],
        Service['supervisor-config'],
        ];
    # 'qpidd':
    #   ensure      => running,
    #   enable      => true,
    #   subscribe   => File['/etc/qpidd.conf'];
    'zookeeper':
      ensure  => "running",
      enable  => "true",
      require => Package["zookeeper"]
  }

  firewall {
   '901 Contrail API agent':
     port   => [8082,8084],
     proto  => 'tcp',
     action => 'accept';
   '902 Contrail SVC monitor':
     port   => 8088,
     proto  => 'tcp',
     action => 'accept';
   '903 Contrail WebUI - http':
     port   => 8080,
     proto  => 'tcp',
     action => 'accept';
   '904 Contrail WebUI - https':
     port   => 8143,
     proto  => 'tcp',
     action => 'accept';
   '905 Contrail API agent TCP':
     port   => [5997,5998],
     proto  => 'tcp',
     action => 'accept';
   '905 Contrail API agent UDP':
     port   => [5998],
     proto  => 'udp',
     action => 'accept';
   '906 Contrail schema transformer':
     port   => [8087],
     proto  => 'tcp',
     action => 'accept';
   '907 Contrail quantum server':
     port   => [9696],
     proto  => 'tcp',
     action => 'accept';
   '909 Contrail IF-map':
     port   => [8443],
     proto  => 'tcp',
     action => 'accept';
   '910 Contrail Zookeeper':
     port   => [2181,2888,3888],
     proto  => 'tcp',
     action => 'accept';
   '911 Contrail HAProxy members':
     port   => [9100,9110],
     proto  => 'tcp',
     action => 'accept';
   }
  
   exec { 'wait_for_supervisor-config' :
     require => Service['supervisor-config'],
     # before  => Exec['create-control-exec'],
     command => "sleep 150 && /etc/init.d/supervisor-analytics restart",
     path => "/usr/bin:/bin",
   }
  
}