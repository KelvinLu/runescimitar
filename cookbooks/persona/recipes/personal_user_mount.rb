#
# Cookbook:: persona
# Recipe:: personal_user_mount
#

include_recipe 'persona::personal_user_bin'

params    = node['persona'].fetch('personal_user')
username  = params.fetch('name')

removable_media = params.fetch('removable_media')

removable_media.each do |uuid, params|
  path = params.fetch('path')
  fstype = params.fetch('fstype', 'auto')

  directory 'mount point' do
    path lazy { File.join(Dir.home(username), path) }

    mode '0751'
  end

  ruby_block 'assert mount point is empty' do
    block { raise 'Expected mount point to be empty' unless Dir.empty?(File.join(Dir.home(username), path)) }

    only_if { get_mount_point(File.join(Dir.home(username), path)) == '/' }
  end

  execute 'set immutable attribute on mount point' do
    command lazy { ['chattr', '+i', File.join(Dir.home(username), path)] }

    only_if { get_mount_point(File.join(Dir.home(username), path)) == '/' }
  end

  mount 'mount point fstab entry' do
    mount_point lazy { File.join(Dir.home(username), path) }

    device uuid
    device_type :uuid

    fstype fstype

    options lazy {
      %w[
        rw nosuid nodev noexec noatime nodiratime noauto user async
        umask=0077
      ] + %W[
        uid=#{Etc.getpwnam(username).uid} gid=#{Etc.getpwnam(username).gid}
      ]
    }
    dump 0
    pass 2

    action :enable
  end
end
