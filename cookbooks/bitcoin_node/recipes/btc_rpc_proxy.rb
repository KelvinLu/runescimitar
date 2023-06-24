#
# Cookbook:: bitcoin_node
# Recipe:: btc_rpc_proxy
#

git_ref = node['bitcoin_node'].fetch('btc_rpc_proxy').fetch('git_ref')

include_recipe 'bitcoin_node::bitcoin_core'
include_recipe 'applications::rust'

user 'btc-rpc-proxy' do
  system true
  home '/var/btc-rpc-proxy'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'bitcoin' do
  append true
  members %w[btc-rpc-proxy]

  action :modify
end

directory '/var/btc-rpc-proxy' do
  group lazy { Etc.getpwnam('btc-rpc-proxy').gid }
  mode '0751'
end

directory '/var/btc-rpc-proxy/conf.d' do
  group lazy { Etc.getpwnam('btc-rpc-proxy').gid }
  mode '0751'
end

directory '/opt/btc-rpc-proxy' do
  mode '0755'
end

directory '/opt/btc-rpc-proxy/bin' do
  mode '0755'
end

directory '/var/opt/btc-rpc-proxy' do
  mode '0755'
end

git '/var/opt/btc-rpc-proxy' do
  repository 'https://github.com/Kixunil/btc-rpc-proxy.git'
  revision git_ref
  depth 1

  only_if { Dir.empty?('/var/opt/btc-rpc-proxy') }
end

execute 'bind mount /var/opt/btc-rpc-proxy' do
  command %w[mount --bind /var/opt/btc-rpc-proxy /var/opt/btc-rpc-proxy]

  only_if { `findmnt -nlf -o options -T /var/opt/btc-rpc-proxy`.strip.split(',').include?('noexec') }

  notifies :run, 'execute[unmount /var/opt/btc-rpc-proxy]', :delayed

  creates '/var/opt/btc-rpc-proxy/target/release/btc_rpc_proxy'
end

execute 'remount /var/opt/btc-rpc-proxy without noexec' do
  command %w[mount -o remount,bind,exec,nosuid,nodev /var/opt/btc-rpc-proxy]

  only_if { `findmnt -nlf -o options -T /var/opt/btc-rpc-proxy`.strip.split(',').include?('noexec') }

  creates '/var/opt/btc-rpc-proxy/target/release/btc_rpc_proxy'
end

execute 'unmount /var/opt/btc-rpc-proxy' do
  command %w[umount /var/opt/btc-rpc-proxy]

  action :nothing
end

execute 'build btc-rpc-proxy' do
  command %w[cargo build --release]
  cwd '/var/opt/btc-rpc-proxy'

  creates '/var/opt/btc-rpc-proxy/target/release/btc_rpc_proxy'
end

file 'install btc_rpc_proxy' do
  path '/opt/btc-rpc-proxy/bin/btc_rpc_proxy'
  content lazy { File.read('/var/opt/btc-rpc-proxy/target/release/btc_rpc_proxy') }

  mode '0755'
end

cookbook_file '/var/btc-rpc-proxy/conf.d/btc-rpc-proxy.toml' do
  source 'btc-rpc-proxy.toml'

  group lazy { Etc.getpwnam('btc-rpc-proxy').gid }
  mode '0640'
end

cookbook_file '/etc/systemd/system/btc-rpc-proxy.service' do
  source 'btc-rpc-proxy.service'

  mode '0640'
end

systemd_unit 'btc-rpc-proxy.service' do
  action :enable
end
