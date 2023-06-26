#
# Cookbook:: lightning_node
# Recipe:: lnd_scb
#

scb_local_dir = node['lightning_node']&.[]('scb_local_dir')
scb_local_user = node['lightning_node']&.[]('scb_backup_user')

include_recipe 'lightning_node::lnd'

unless scb_local_dir.nil?
  apt_package 'inotify-tools' do
    action :install
  end

  directory '/opt/lnd-scb' do
    mode '0755'
  end

  directory '/opt/lnd-scb/bin' do
    mode '0755'
  end

  cookbook_file '/opt/lnd-scb/bin/scb-backup.sh' do
    source 'scb-backup.sh'

    mode '0755'
  end

  template '/etc/systemd/system/lnd-scb.service' do
    source 'lnd-scb.service.erb'

    variables(
      backup_dir: scb_local_dir,
      backup_user: scb_local_user
    )

    mode '0640'
  end

  systemd_unit 'lnd-scb.service' do
    action :enable
  end
end
