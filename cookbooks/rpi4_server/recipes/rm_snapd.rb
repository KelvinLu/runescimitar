#
# Cookbook:: rpi4_server
# Recipe:: rm_snapd
#
# Copyright:: 2022, The Authors, All Rights Reserved.

apt_package 'snapd' do
  action :remove
end
