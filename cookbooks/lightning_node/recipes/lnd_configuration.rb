#
# Cookbook:: lightning_node
# Recipe:: lnd_configuration
#

split_tunnel_vpn_params = node['lightning_node']&.[]('split_tunnel_vpn')

node.default['lightning_node']['lnd']['cgroups'] = [*(split_tunnel_vpn_params.nil? ? nil : 'net_cls:lightning_vpn')]
node.default['lightning_node']['lnd']['hybrid_mode'] = false

ruby_block 'check node alias file' do
  block do
    unless File.exist?('/var/lnd/.node-alias.txt') && !File.zero?('/var/lnd/.node-alias.txt')
      raise 'A node alias must be set in a file located at ~lnd/.node-alias.txt'
    end
  end
end

ruby_block 'check split tunnel VPN configuration for hybrid mode' do
  block do
    if node['lightning_node']['lnd']['hybrid_mode']
      if node['lightning_node']&.[]('split_tunnel_vpn').nil?
        raise 'Split tunnel VPN configuration is missing for enabling LND hybrid mode'
      end
    end
  end
end

template '/var/lnd/.lnd/lnd.conf' do
  source 'lnd.conf.erb'

  variables lazy {
    node_alias = File.read('/var/lnd/.node-alias.txt').strip

    external_host =
      if File.exists?('/var/lnd/.external-host.txt')
        File.read('/var/lnd/.external-host.txt').strip
      else
        nil
      end

    hybrid_mode = node['lightning_node']['lnd']['hybrid_mode']

    {
      node_alias: node_alias,
      external_host: external_host,
      hybrid_mode: hybrid_mode,
    }
  }

  group lazy { Etc.getpwnam('lnd').gid }

  mode '0640'
end

template '/etc/systemd/system/lnd.service' do
  source 'lnd.service.erb'

  variables lazy {
    {
      after_units: node['lightning_node'].[]('service_require')&.[]('lnd.service'),
      lnd_command: (
        if node['lightning_node']['lnd']['cgroups'].empty?
          '/usr/local/bin/lnd'
        else
          cgroup_params = node['lightning_node']['lnd']['cgroups'].map { |param| "-g #{param}" }.join(' ')
          "/usr/bin/cgexec #{cgroup_params} /usr/local/bin/lnd"
        end
      ),
    }
  }

  mode '0640'
end

systemd_unit 'lnd.service' do
  action :enable
end
