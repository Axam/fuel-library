class contrail::common {
    
  package {
    'supervisor':
      ensure => '0.1-1.05.215m1.el6';
    # 'qpid-cpp-server':
    #   ensure => installed,
    #   before => Service[qpidd];
  }

  exec { 
    'create-python-api-env':
      command  => "source /opt/contrail/api-venv/bin/activate && /opt/contrail/api-venv/bin/pip install /opt/contrail/api-venv/archive/* && touch /etc/contrail/api-venv.done",
      require  => Package['supervisor','python-novaclient','python-keystoneclient','python-neutronclient','contrail-api-lib','contrail-api-extension','contrail-config','contrail-setup','python-psutil','euca2ools','m2crypto'],
      provider => 'shell',
      creates  => '/etc/contrail/api-venv.done';
   'create-python-analytics-env':
      command  => "source /opt/contrail/analytics-venv/bin/activate && /opt/contrail/analytics-venv/bin/pip install /opt/contrail/analytics-venv/archive/* && touch /etc/contrail/analytics-venv.done",
      require  => Package['supervisor','python-novaclient','python-keystoneclient','python-neutronclient','contrail-api-lib','contrail-api-extension','contrail-config','contrail-setup','python-psutil','euca2ools','m2crypto'],
      provider => 'shell',
      creates  => '/etc/contrail/analytics-venv.done';
   'create-python-control-env':
      command  => "source /opt/contrail/control-venv/bin/activate && /opt/contrail/control-venv/bin/pip install /opt/contrail/control-venv/archive/* && touch /etc/contrail/control-venv.done",
      require  => Package['supervisor','python-novaclient','python-keystoneclient','python-neutronclient','contrail-api-lib','contrail-api-extension','contrail-config','contrail-setup','python-psutil','euca2ools','m2crypto'],
      provider => 'shell',
      creates  => '/etc/contrail/control-venv.done';
  }

}
