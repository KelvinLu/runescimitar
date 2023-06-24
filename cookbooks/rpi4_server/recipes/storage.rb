#
# Cookbook:: rpi4_server
# Recipe:: storage
#

STORAGE_DIR = '/storage'

apt_package 'iotop' do
  action :install
end

directory STORAGE_DIR do
  mode '0755'
end

node['rpi4_server']&.[]('storage')&.[]('mount').each do |uuid, params|
  path = params.fetch('path')
  fstype = params.fetch('fstype', 'auto')

  mountpoint = File.join(STORAGE_DIR, path)

  directory mountpoint do
    mode '0751'
  end

  ruby_block "assert #{mountpoint} is empty" do
    block { raise "Expected #{mountpoint} to be empty" unless Dir.empty?(mountpoint) }

    only_if { get_mount_point(mountpoint) == '/' }
  end

  execute "set immutable attribute #{mountpoint}" do
    command ['chattr', '+i', mountpoint]

    only_if { get_mount_point(mountpoint) == '/' }
  end

  mount mountpoint do
    device uuid
    device_type :uuid

    fstype fstype

    options %w[
      rw nosuid nodev noexec noatime nodiratime auto nouser async nofail
      x-systemd.device-timeout=10s
    ]
    dump 0
    pass 2

    action :enable
  end
end
