#
# Cookbook:: applications
# Recipe:: rust
#
# Copyright:: 2022, The Authors, All Rights Reserved.

apt_package 'rustc' do
  action :install
end

apt_package 'cargo' do
  action :install
end
