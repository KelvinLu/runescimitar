#
# Cookbook:: lightning_node
# Recipe:: lnd_configuration
#
# Copyright:: 2022, The Authors, All Rights Reserved.

ruby_block 'check node alias file' do
  block do
    unless File.exist?('/var/lnd/.node-alias.txt') && !File.zero?('/var/lnd/.node-alias.txt')
      raise 'A node alias must be set in a file located at ~lnd/.node-alias.txt'
    end
  end
end

template '/var/lnd/.lnd/lnd.conf' do
  source 'lnd.conf.erb'

  variables lazy {
    node_alias = File.read('/var/lnd/.node-alias.txt').strip

    { node_alias: node_alias }
  }

  group lazy { Etc.getpwnam('lnd').gid }

  mode '0640'
end

template '/etc/systemd/system/lnd.service' do
  source 'lnd.service.erb'

  variables(
    after_units: node['lightning_node'].[]('service_require')&.[]('lnd.service')
  )

  mode '0640'
end

systemd_unit 'lnd.service' do
  action :enable
end
