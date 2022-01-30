#
# Cookbook:: rpi4_server
# Recipe:: rm_unattended_upgrades
#
# Copyright:: 2022, The Authors, All Rights Reserved.

apt_package 'unattended-upgrades' do
  action :remove
end
