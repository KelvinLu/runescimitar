#
# Cookbook:: rpi4_server
# Recipe:: rm_unattended_upgrades
#

apt_package 'unattended-upgrades' do
  action :remove
end
