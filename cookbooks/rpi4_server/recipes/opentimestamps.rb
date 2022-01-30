#
# Cookbook:: rpi4_server
# Recipe:: opentimestamps
#
# Copyright:: 2022, The Authors, All Rights Reserved.

operator_user = node['rpi4_server'].fetch('operator_user')

apt_package 'python3' do
  action :install
end

apt_package 'python3-dev' do
  action :install
end

apt_package 'python3-pip' do
  action :install
end

apt_package 'python3-setuptools' do
  action :install
end

apt_package 'python3-wheel' do
  action :install
end

execute 'pip3 install opentimestamps-client' do
  command %w[pip3 install opentimestamps-client]

  only_if { `which ots`.empty? }
end
