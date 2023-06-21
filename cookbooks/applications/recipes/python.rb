#
# Cookbook:: applications
# Recipe:: python
#
# Copyright:: 2022, The Authors, All Rights Reserved.

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
