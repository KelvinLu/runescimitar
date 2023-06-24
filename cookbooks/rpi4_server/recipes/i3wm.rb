#
# Cookbook:: rpi4_server
# Recipe:: i3wm
#

apt_package 'i3' do
  action :install
end

apt_package 'xinit' do
  action :install
end

apt_package 'x11-utils' do
  action :install
end

apt_package 'x11-xserver-utils' do
  action :install
end

apt_package 'conky' do
  action :install
end

include_recipe 'rpi4_server::i3_config'
