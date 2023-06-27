#
# Cookbook:: rpi4_server
# Recipe:: vpn
#

apt_package 'wireguard' do
  action :install
end

apt_package 'nftables' do
  action :install
end
