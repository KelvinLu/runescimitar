#
# Cookbook:: rpi4_server
# Recipe:: vpn_client_nat_pmp
#

params = node['rpi4_server']&.[]('vpn_client_nat_pmp')

include_recipe 'rpi4_server::vpn'
include_recipe 'rpi4_server::ufw'

apt_package 'natpmpc' do
  action :install
end

apt_package 'resolvconf' do
  action :install
end

directory '/opt/vpn-client-nat-pmp' do
  mode '0755'
end

directory '/etc/vpn-client-nat-pmp' do
  mode '0755'
end

cookbook_file '/opt/vpn-client-nat-pmp/natpmpc.sh' do
  source 'vpn-client-nat-pmp.sh'

  mode '0644'
end

cookbook_file '/etc/systemd/system/vpn-client-nat-pmp@.service' do
  source 'vpn-client-nat-pmp@.service'

  mode '0644'
end

cookbook_file '/etc/systemd/system/vpn-client-nat-pmp@.timer' do
  source 'vpn-client-nat-pmp@.timer'

  mode '0644'
end

params.each do |interface_name, configuration|
  wireguard_conf_file = File.join('/etc/wireguard', "#{interface_name}.conf")
  gateway             = configuration.fetch('gateway')
  port                = configuration.fetch('port')

  directory File.join('/etc/vpn-client-nat-pmp', interface_name) do
    mode '0755'
  end

  file File.join('/etc/vpn-client-nat-pmp', interface_name, 'gateway') do
    mode '0600'

    content gateway

    action :create_if_missing
  end

  file File.join('/etc/vpn-client-nat-pmp', interface_name, 'port') do
    mode '0600'

    content port.to_s

    action :create_if_missing
  end

  ruby_block "ensure #{wireguard_conf_file} exists" do
    block do
      raise "Expected a WireGuard configuration at #{wireguard_conf_file}" unless File.exist?(wireguard_conf_file)
    end
  end

  systemd_unit "wg-quick@#{interface_name}.service" do
    action :enable
  end

  systemd_unit "vpn-client-nat-pmp@#{interface_name}.service" do
    action :enable
  end

  systemd_unit "vpn-client-nat-pmp@#{interface_name}.timer" do
    action :enable
  end

  execute "ensure interface device #{interface_name} exists" do
    command [*%w[ip link show], interface_name]
  end

  execute 'ufw allow vpn port forwarding connection' do
    command lazy {
      [*%w[ufw allow in on], interface_name, *%w[to any port], port.to_s, *%w[proto tcp comment], "Allow #{interface_name} port forwarding (VPN NAT-PMP, port #{port})"]
    }

    not_if do
      `ufw status verbose | grep -q '#{port}/tcp on #{interface_name}.*ALLOW IN'`
      $?.success?
    end

    notifies :run, 'execute[ufw reload]', :delayed
  end
end
