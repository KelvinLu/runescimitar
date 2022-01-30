#
# Cookbook:: bitcoin_users
# Recipe:: guest_user_workspace
#
# Copyright:: 2022, The Authors, All Rights Reserved.

params = node['bitcoin_users'].fetch('guest_user')
username = params.fetch('name')

user_home_dir = File.join('/storage/data/', username, 'home/')
workspace_dir = File.join('/storage/data/', username, 'home/', username, 'workspace/')

tmpfs_size_mb = params.fetch('tmpfs_workspace').fetch('size_mb')

directory workspace_dir do
  user lazy { Etc.getpwnam(username).uid }
  group lazy { Etc.getpwnam(username).gid }
  mode '0700'
end

ruby_block "assert #{workspace_dir} is empty" do
  block { raise "Expected #{workspace_dir} to be empty" unless Dir.empty?(workspace_dir) }

  only_if { get_mount_point(workspace_dir) == '/storage/data' }
end

execute "set immutable attribute #{workspace_dir}" do
  command ['chattr', '+i', workspace_dir]

  only_if { get_mount_point(workspace_dir) == '/storage/data' }
end

ruby_block 'Add user mount for tmpfs workspace' do
  block do
    options = %w[
      rw nosuid nodev noexec noatime nodiratime auto user async nofail
      mode=0700
      x-systemd.device-timeout=10s
    ] + %W[
      size=#{tmpfs_size_mb}M
      uid=#{Etc.getpwnam(username).uid} gid=#{Etc.getpwnam(username).gid}
    ]
    file = Chef::Util::FileEdit.new('/etc/fstab')

    config_line = "tmpfs #{workspace_dir} tmpfs #{options.join(',')} 0 0"
    prefix_pattern = /^tmpfs #{Regexp.quote(workspace_dir)}/
    file.search_file_replace_line(prefix_pattern, config_line)
    file.insert_line_if_no_match(prefix_pattern, config_line)

    file.write_file
  end
end

cookbook_file File.join(user_home_dir, '.workspace_ps1') do
  source '.workspace_ps1_guest'

  group lazy { Etc.getpwnam(username).gid }
  mode '0750'
end
