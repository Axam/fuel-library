class contrail::database (
  $host_ip             = undef,
  $discovery_server_ip = undef,
){
  package { 'contrail-openstack-database':
    ensure => present
  }
 
  package { 'contrail-openstack-database-venv':
    ensure => present
  }

  file { 
    '/etc/alternatives/cassandra/cassandra.yaml':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      content => template('/etc/puppet/modules/contrail/templates/cassandra.yaml.erb'),
      require => Package['contrail-openstack-database'];
    '/etc/alternatives/cassandra/cassandra-env.sh':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      source  => 'puppet:///modules/contrail/cassandra-env.sh',
      require => Package['contrail-openstack-database'];
  }

  service { 'supervisord-contrail-database':
    ensure      => running,
    enable      => true,
    require     => [
      File['/etc/alternatives/cassandra/cassandra.yaml','/etc/alternatives/cassandra/cassandra-env.sh'],
      Exec['create-python-database-venv'],
      Exec['create-python-analytics-env']
    ]
  }
  
  firewall {
    '908 Contrail Cassandra':
      port   => [9160,7000,7199],
      proto  => 'tcp',
      action => 'accept';
  }
  
  
  exec { 'create-python-database-venv':
    command  => "source /opt/contrail/database-venv/bin/activate && touch /etc/contrail/database-venv.done",
    require  => Package['contrail-openstack-database'],
    provider => 'shell',
    creates  => '/etc/contrail/database-venv.done';
  }
  
}