#
# Cookbook:: lightning_node
# Recipe:: lnd_configuration
#

split_tunnel_vpn_params = node['lightning_node']&.[]('split_tunnel_vpn')
neutrino_mode_params = node['lightning_node']&.[]('lnd')&.[]('neutrino_mode')

node.default['lightning_node']['lnd']['cgroups'] = [*(split_tunnel_vpn_params.nil? ? nil : 'net_cls:lightning_vpn')]
node.default['lightning_node']['lnd']['hybrid_mode'] = false

ruby_block 'check node alias file' do
  block do
    unless File.exist?('/var/lnd/.node-alias.txt') && !File.zero?('/var/lnd/.node-alias.txt')
      raise 'A node alias must be set in a file located at ~lnd/.node-alias.txt'
    end
  end
end

ruby_block 'check node color file' do
  block do
    unless File.exist?('/var/lnd/.node-color.txt') && !File.zero?('/var/lnd/.node-color.txt')
      raise 'A node color must be set in a file located at ~lnd/.node-color.txt'
    end

    node_color = File.read('/var/lnd/.node-color.txt').strip

    raise 'Invalid color code' unless node_color.match?(/^#[0-9A-Fa-f]{6}$/)
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
    node_color = File.read('/var/lnd/.node-color.txt').strip

    hybrid_mode = node['lightning_node']['lnd']['hybrid_mode']

    external_host =
      if File.exists?('/var/lnd/.external-host.txt')
        File.read('/var/lnd/.external-host.txt').strip
      else
        nil
      end

    rest_api_interfaces = node['lightning_node']['lnd']['rest_api_interfaces']&.map do |interface|
      `ip -brief addr show '#{interface}'`.strip.split[2].split('/').first
    end

    tlsextraip_addresses =
      if File.exists?('/var/lnd/.tls-ip-addresses.txt')
        File.read('/var/lnd/.tls-ip-addresses.txt').lines.map(&:strip).compact
      else
        nil
      end

    {
      node_alias: node_alias,
      node_color: node_color,
      hybrid_mode: hybrid_mode,
      external_host: external_host,
      rest_api_interfaces: rest_api_interfaces,
      tlsextraip_addresses: tlsextraip_addresses,
      neutrino_mode: !neutrino_mode_params.nil?,
      neutrino_mode_params: neutrino_mode_params,
    }
  }

  group lazy { Etc.getpwnam('lnd').gid }

  mode '0640'
end

template '/etc/systemd/system/lnd.service' do
  source 'lnd.service.erb'

  variables lazy {
    {
      neutrino_mode: !neutrino_mode_params.nil?,
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
