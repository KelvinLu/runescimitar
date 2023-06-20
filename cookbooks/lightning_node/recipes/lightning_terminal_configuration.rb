#
# Cookbook:: lightning_node
# Recipe:: lightning_terminal_configuration
#
# Copyright:: 2022, The Authors, All Rights Reserved.

include_recipe 'bitcoin_node::btc_rpc_proxy'
include_recipe 'rpi4_server::ufw'

ruby_block 'check uipassword file' do
  block do
    unless File.exist?('/var/lightning-terminal/.uipassword.txt') && !File.zero?('/var/lightning-terminal/.uipassword.txt')
      raise 'A UI password must be set in a file located at ~lightning-terminal/.uipassword.txt'
    end

    unless File.stat('/var/lightning-terminal/.uipassword.txt').mode & 07777 == 0600
      raise '.uipassword.txt must have file permissions of 0600'
    end

    unless File.stat('/var/lightning-terminal/.uipassword.txt').uid == Etc.getpwnam('lightning-terminal').uid
      raise '.uipassword.txt must owned by user lightning-terminal'
    end
  end
end

file '/var/lightning-terminal/.faraday/.bitcoind-password' do
  content lazy { `gpg --gen-random --armor 1 32`.strip }
  sensitive true

  user lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0600'

  action :create_if_missing
end

template '/var/btc-rpc-proxy/conf.d/faraday.toml' do
  source 'btc-rpc-proxy_faraday.toml.erb'
  sensitive true

  variables lazy {
    bitcoind_password = File.read('/var/lightning-terminal/.faraday/.bitcoind-password')

    { bitcoind_password: bitcoind_password }
  }

  group lazy { Etc.getpwnam('btc-rpc-proxy').gid }

  mode '0640'

  notifies :restart, 'systemd_unit[btc-rpc-proxy.service]', :delayed
end

template '/var/lightning-terminal/.lit/lit.conf' do
  source 'lit.conf.erb'
  sensitive true

  variables lazy {
    faraday_bitcoind_password = File.read('/var/lightning-terminal/.faraday/.bitcoind-password')

    { faraday_bitcoind_password: faraday_bitcoind_password }
  }

  user lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }

  mode '0600'
end

cookbook_file '/etc/systemd/system/litd.service' do
  source 'litd.service'

  mode '0644'
end

systemd_unit 'litd.service' do
  action :enable
end

execute 'ufw allow lightning terminal connection' do
  command [*%w[ufw allow from 192.168.0.0/16 to any port 8443 proto tcp comment], 'Allow Lightning Terminal']

  not_if do
    `ufw status verbose | grep -q '8443/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end
