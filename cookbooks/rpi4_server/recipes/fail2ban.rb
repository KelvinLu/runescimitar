#
# Cookbook:: rpi4_server
# Recipe:: fail2ban
#
# Copyright:: 2022, The Authors, All Rights Reserved.

apt_package 'fail2ban' do
  action :install
end
