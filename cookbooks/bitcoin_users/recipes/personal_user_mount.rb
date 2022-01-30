#
# Cookbook:: bitcoin_users
# Recipe:: personal_user_mount
#
# Copyright:: 2022, The Authors, All Rights Reserved.

include_recipe 'bitcoin_users::personal_user_bin'

params    = node['bitcoin_users'].fetch('personal_user')
username  = params.fetch('name')

removable_media = params.fetch('removable_media')

removable_media.each do |uuid, params|
  path = params.fetch('path')
  fstype = params.fetch('fstype', 'auto')

  mountpoint = File.join(Dir.home(username), path)

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
      rw nosuid nodev noexec noatime nodiratime noauto user async
      umask=0077
    ] + %W[
      uid=#{Etc.getpwnam(username).uid} gid=#{Etc.getpwnam(username).gid}
    ]
    dump 0
    pass 2

    action :enable
  end
end
