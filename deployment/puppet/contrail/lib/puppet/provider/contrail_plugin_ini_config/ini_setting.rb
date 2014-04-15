Puppet::Type.type(:contrail_plugin_ini_config).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:name].split('/', 2).first
  end

  def setting
    resource[:name].split('/', 2).last
  end

  def separator
    '='
  end

  def file_path
    '/etc/quantum/plugins/contrail/contrail_plugin.ini'
  end

end
