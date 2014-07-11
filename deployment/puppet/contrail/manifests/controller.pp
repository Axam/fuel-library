class contrail::controller (
  $collector_ip               = undef,
  $api_ip                     = undef,
  $host_ip                    = undef,
  $discovery_server_ip        = undef,
  $as_number                  = undef,
  $admin_user                 = undef,
  $admin_pass                 = undef,
  $quantum_user               = undef,
  $quantum_pass               = undef,
  $wan_gateways               = undef,
  $encapsulation              = undef,
  $sdn_controllers_node_names = undef,
  $sdn_controllers_node_list  = undef,
){
  package {'contrail-openstack-control':
    ensure => installed,
  }

  file {
    '/etc/contrail/control_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [ 
         Package['contrail-openstack-control'],
         Exec['create-python-control-env'],
         Exec['create-python-api-env'],
         Exec['create-python-analytics-env']
        ],
      content => template('/etc/puppet/modules/contrail/templates/control_param.erb');
    '/etc/contrail/dns_param':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [
        Package['contrail-openstack-control'],
        Exec['create-python-control-env'],
        Exec['create-python-api-env'],
        Exec['create-python-analytics-env']
      ],
      content => template('/etc/puppet/modules/contrail/templates/dns_param.erb');
    '/etc/contrail/dns/named.conf':
      ensure  => present,
      mode    => '0644',
      owner   => root,
      group   => root,
      require => [
        Package['contrail-openstack-control'],
        Exec['create-python-api-env'],
        Exec['create-python-control-env'],
        Exec['create-python-analytics-env']
      ],
      source  => 'puppet:///modules/contrail/named.conf';
    '/etc/init.d/contrail-dns':
      notify  => Service['contrail-dns'],
      ensure  => present,
      source  => 'puppet:///modules/contrail/contrail-dns',
      mode    => '0731',
      owner   => 'root',
      group   => 'root';
    '/etc/init.d/contrail-named':
      notify  => Service['contrail-named'],
      ensure  => present,
      source  => 'puppet:///modules/contrail/contrail-named',
      mode    => '0731',
      owner   => 'root',
      group   => 'root';
    }

  service {
    'supervisor-control':
      ensure      => running,
      enable      => true,
      notify      => Service['supervisor-analytics'],
      require     => File['/etc/contrail/control_param'];
    'contrail-named':
      ensure      => running,
      enable      => true,
      require     => File['/etc/contrail/dns_param', '/etc/init.d/contrail-named'];
    'contrail-dns':
      notify      => Service ['supervisor-control'],
      ensure      => running,
      enable      => true,
      require     => File['/etc/contrail/dns_param', '/etc/init.d/contrail-dns'];
  }
 
  firewall {
   '911 Contrail - vRouter communication':
     port   => [5269,8093],
     proto  => 'tcp',
     action => 'accept';
   '911 Contrail - BGP':
     port   => [179],
     proto  => 'tcp',
     action => 'accept';
  }
 
  # exec { 'create-control-exec':
  #   command  => "/usr/bin/python /opt/contrail/utils/provision_control.py --api_server_ip ${api_ip} --api_server_port 8082 --oper add --host_name ${::fqdn} --host_ip ${host_ip} --router_asn ${as_number} --admin_user ${admin_user} --admin_password ${admin_pass} --admin_tenant_name services && touch /etc/contrail/ctrl-provision.done",
  #   require  => [File['/etc/contrail/control_param'], Service['supervisor-config'], Service['supervisor-control']],
  #   path     => '/bin',
  #   creates  => '/etc/contrail/ctrl-provision.done';
  # }
 
  define createCTRL() {
    $ctrl_ip = $quantum_config['contrail']["sdn_controller_${name}"]
    exec { "create-control-$name":
      command  => "/usr/bin/python /opt/contrail/utils/provision_control.py --api_server_ip ${api_ip} --api_server_port 8082 --oper add --host_name ${name} --host_ip ${ctrl_ip} --router_asn ${as_number} --admin_user ${quantum_user} --admin_password ${quantum_pass} --admin_tenant_name services && touch /etc/contrail/ctrl-provision-${name}.done",
      require  => [File['/etc/contrail/control_param'], Service['supervisor-config'], Service['supervisor-control'], Exec['wait_for_supervisor-config']],
      path     => '/bin',
      creates  => '/etc/contrail/ctrl-provision-$name.done';
    }
    notify{ "SDN controller node name: ${name}": }
    notify{ "SDN controller IP is: ${ctrl_ip}": }
  }

  notify{ "SDN controller node names: ${sdn_controllers_node_names}": }
  notify{ "SDN controller node list: ${sdn_controllers_node_list}": }
  notify{ "WAN Gateways: ${wan_gateways}": }
  

  if $sdn_controllers_node_list[-1] == $host_ip {
    createCTRL { $sdn_controllers_node_names:}
  }

  define addMX() {
    $mx_ip = $quantum_config['contrail']["wan_gateways_${name}"]
    exec {"createMX$name":
      command  => "/usr/bin/python /opt/contrail/utils/provision_mx.py  --api_server_ip ${api_ip} --api_server_port 8082 --oper add --router_name ${name} --router_ip ${mx_ip} --router_asn ${as_number} --admin_user ${quantum_user} --admin_password ${quantum_pass} --admin_tenant_name services && touch /etc/contrail/mx-${name}-provision.done",
      provider => 'shell',
      path     => '/bin',
      require  => [File['/etc/contrail/control_param'], Service['supervisor-config'], Service['supervisor-control'], Exec['wait_for_supervisor-config']], 
      creates  => "/etc/contrail/mx-${name}-provision.done",
    }
    # notify{ "Gateway name is: ${name}": }
    # notify{ "IP address is: ${mx_ip}": }
  }
  
  if $wan_gateways != '' and $sdn_controllers_node_list[-1] == $host_ip {
    addMX { $wan_gateways:}
  }
     
  
 if $sdn_controllers_node_list[-1] == $host_ip {
  
   exec {'ASnumber-bugFix-exec':
     command => "source /opt/contrail/api-venv/bin/activate && python -c \"from vnc_api import vnc_api;lib=vnc_api.VncApi();gsc_obj=lib.global_system_config_read(fq_name=['default-global-system-config']);gsc_obj.autonomous_system=${as_number};lib.global_system_config_update(gsc_obj)\" && touch /etc/contrail/asnumber-fix.done",
     provider => 'shell',
     require  => [Service['supervisor-config'], Service['supervisor-control']],
     path     => '/bin',
     creates  => '/etc/contrail/asnumber_fix.done';
   }  
    
  case $encapsulation {
       'MPLSoGRE': { 
      exec { 'encap-MPLSoGRE-exec':
 	      command  => "/usr/bin/python /opt/contrail/utils/provision_encap.py --admin_user ${admin_user} --admin_password ${admin_pass} --encap_priority MPLSoGRE,MPLSoUDP,VXLAN --oper add && touch /etc/contrail/encap.done",
        provider => 'shell',
        require  => [Service['supervisor-config'], Service['supervisor-control']],
 	      path     => '/bin',
 	      creates  => '/etc/contrail/encap.done';
 	    }
 	  }
       'MPLSoUDP': { 
 	    exec { 'encap-MPLSoUDP-exec':
 	      command  => "/usr/bin/python /opt/contrail/utils/provision_encap.py --admin_user ${admin_user} --admin_password ${admin_pass} --encap_priority MPLSoUDP,MPLSoGRE,VXLAN --oper add && touch /etc/contrail/encap.done",
        provider => 'shell',
        require  => [Service['supervisor-config'], Service['supervisor-control']],
 	      path     => '/bin',
 	      creates  => '/etc/contrail/encap.done';
 	    }
 		}
       'VxLAN': { 
 	    exec { 'encap-VXLAN-exec':
 	      command  => "/usr/bin/python /opt/contrail/utils/provision_encap.py --admin_user ${admin_user} --admin_password ${admin_pass} --encap_priority VXLAN,MPLSoGRE,MPLSoUDP, --oper add && touch /etc/contrail/encap.done",
        provider => 'shell',
        require  => [Service['supervisor-config'], Service['supervisor-control']],
 	      path     => '/bin',
 	      creates  => '/etc/contrail/encap.done';
 	    }
 		}
  } 
 }
}

