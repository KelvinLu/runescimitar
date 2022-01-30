#
# Cookbook:: rpi4_server
# Recipe:: rm_cloudinit
#
# Copyright:: 2022, The Authors, All Rights Reserved.

file '/etc/cloud/cloud-init.disabled' do
  action :create_if_missing
end

file '/etc/cloud/cloud.cfg.d/90_dpkg.cfg' do
  content <<~CFG
    # Modified by Chef
    datasource_list: [ None ]
  CFG

  not_if { `tail -n1 /etc/cloud/cloud.cfg.d/90_dpkg.cfg`.strip == 'datasource_list: [ None ]' }

  notifies :run, 'execute[reload cloud-init configuration]', :immediate
end

execute 'reload cloud-init configuration' do
  command %w[dpkg-reconfigure -f noninteractive cloud-init]

  action :nothing
end

apt_package 'cloud-init' do
  action :purge
end
