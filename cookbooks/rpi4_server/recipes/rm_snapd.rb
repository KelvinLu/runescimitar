#
# Cookbook:: rpi4_server
# Recipe:: rm_snapd
#

apt_package 'snapd' do
  action :remove
end
