#
# Cookbook:: rpi4_server
# Recipe:: fail2ban
#

apt_package 'fail2ban' do
  action :install
end
