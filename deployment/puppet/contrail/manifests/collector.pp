class contrail::collector (
  $host_ip             = undef,
  $database_ip         = undef,
  $discovery_server_ip = undef,
  ){
    
  package {
    'contrail-openstack-analytics':
      ensure  => installed,
      require => Package[supervisor];
    # 'qpid-cpp-server':
    # ensure => installed,
    # before => Service[qpidd];
  }
  
  file {
    '/etc/contrail/opserver_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-openstack-analytics'],
      content => template('/etc/puppet/modules/contrail/templates/opserver_param.erb');
    '/etc/contrail/vizd_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-openstack-analytics'],
      content => template('/etc/puppet/modules/contrail/templates/vizd_param.erb');
    '/etc/contrail/qe_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-openstack-analytics'],
      content => template('/etc/puppet/modules/contrail/templates/qe_param.erb');        
    '/etc/contrail/sentinel.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => Package['contrail-openstack-analytics'],
      content => template('/etc/puppet/modules/contrail/templates/sentinel.conf.erb');  
  }
  
  service {'supervisor-analytics':
    ensure      => running,
    enable      => true,
    require     => [
      File['/etc/contrail/opserver_param', '/etc/contrail/vizd_param', '/etc/contrail/qe_param', '/etc/contrail/sentinel.conf'],
      Exec['create-python-analytics-env']
    ];
  }
    
  firewall {
   '901 Contrail Redis':
     port   => [26379,6380,6381,6382],
     proto  => 'tcp',
     action => 'accept';
   '902 Contrail opserver':
     port   => [8081,8090],
     proto  => 'tcp',
     action => 'accept';
   '903 Contrail qed':
     port   => 8091,
     proto  => 'tcp',
     action => 'accept';
   '904 Contrail wizd':
     port   => [8086,8089],
     proto  => 'tcp',
     action => 'accept';   
   '905 Contrail nodemgr':
     port   =>  8099,
     proto  => 'tcp',
     action => 'accept';     
   }

}
