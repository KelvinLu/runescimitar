#
# Cookbook:: lightning_node
# Recipe:: split_tunnel_vpn
#

params = node['lightning_node']&.[]('split_tunnel_vpn')

include_recipe 'lightning_node::lnd'
include_recipe 'rpi4_server::vpn'

unless params.nil?
  node.default['lightning_node']['lnd']['cgroups'].append('net_cls:lightning_vpn')

  wireguard_conf_file = params.fetch('wireguard')
  instance_name = File.basename(wireguard_conf_file).delete_suffix('.conf')

  tc_handle = params.fetch('traffic_control_handle')

  apt_package 'cgroup-tools' do
    action :install
  end

  ruby_block "ensure #{wireguard_conf_file} exists" do
    block do
      raise "Expected a WireGuard configuration at #{wireguard_conf_file}" unless File.exist?(wireguard_conf_file)
    end
  end

  directory '/opt/lightning-vpn' do
    mode '0755'
  end

  template '/opt/lightning-vpn/create-split-tunnel-cgroup.sh' do
    source 'create-split-tunnel-cgroup.sh.erb'

    variables(
      tc_handle: tc_handle
    )

    mode '0755'
  end

  cookbook_file '/etc/systemd/system/lightning-vpn-create-cgroup.service' do
    source 'lightning-vpn-create-cgroup.service'

    mode '0644'
  end

  systemd_unit 'lightning-vpn-create-cgroup.service' do
    action :enable
  end

  directory '/etc/systemd/system/lnd.service.d' do
    mode '0755'
  end

  template '/etc/systemd/system/lnd.service.d/lightning-vpn.conf' do
    source 'lightning-vpn.conf.erb'

    variables(
      instance_name: instance_name
    )

    mode '0644'
  end

  cookbook_file '/opt/lightning-vpn/add-processes-split-tunnel.sh' do
    source 'add-processes-split-tunnel.sh'

    mode '0755'
  end

  cookbook_file '/etc/systemd/system/lightning-vpn-split-tunnel.service' do
    source 'lightning-vpn-split-tunnel.service'

    mode '0644'
  end

  cookbook_file '/etc/systemd/system/lightning-vpn-split-tunnel.timer' do
    source 'lightning-vpn-split-tunnel.timer'

    mode '0644'
  end

  systemd_unit 'lightning-vpn-split-tunnel.service' do
    action :enable
  end

  systemd_unit 'lightning-vpn-split-tunnel.timer' do
    action :enable
  end

  systemd_unit "wg-quick@#{instance_name}.service" do
    action :enable
  end

  directory '/etc/lightning-vpn' do
    mode '0755'
  end

  ruby_block 'obtain external host from /etc/lightning-vpn/.external-host.txt' do
    block do
      unless File.exist?('/etc/lightning-vpn/.external-host.txt') && !File.zero?('/etc/lightning-vpn/.external-host.txt')
        raise 'The VPN external host (i.e.; "<host>:<port>") should be set in the file /etc/lightning-vpn/.external-host.txt'
      end
    end
  end

  link '/var/lnd/.external-host.txt' do
    to '/etc/lightning-vpn/.external-host.txt'

    notifies :create, 'template[/var/lnd/.lnd/lnd.conf]', :delayed
  end
end
