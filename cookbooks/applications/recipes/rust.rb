#
# Cookbook:: applications
# Recipe:: rust
#

apt_package 'rustc' do
  action :install
end

apt_package 'cargo' do
  action :install
end
