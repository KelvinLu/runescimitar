#
# Cookbook:: persona
# Recipe:: personal_user_workspace
#

root_location = node['persona'].fetch('root_location', '/home')
params        = node['persona'].fetch('personal_user')
username      = params.fetch('name')

user_home_dir = File.join(root_location, username, 'home/')
workspace_dir = File.join(root_location, username, 'home/', username, 'workspace/')
encrypted_dir = File.join(root_location, username, 'home/', username, '.workspace/')

apt_package 'gocryptfs' do
  action :install
end

directory workspace_dir do
  user lazy { Etc.getpwnam(username).uid }
  group lazy { Etc.getpwnam(username).gid }
  mode '0700'
end

directory encrypted_dir do
  user lazy { Etc.getpwnam(username).uid }
  group lazy { Etc.getpwnam(username).gid }
  mode '0700'
end

ruby_block 'Add user mount for gocryptfs workspace' do
  block do
    options = %w[
      rw nosuid nodev noexec noauto user async nonempty nosyslog
    ]
    file = Chef::Util::FileEdit.new('/etc/fstab')

    config_line = "#{encrypted_dir} #{workspace_dir} fuse./usr/bin/gocryptfs #{options.join(',')} 0 0"
    prefix_pattern = /^#{Regexp.quote(encrypted_dir)}/
    file.search_file_replace_line(prefix_pattern, config_line)
    file.insert_line_if_no_match(prefix_pattern, config_line)

    file.write_file
  end
end

file File.join(user_home_dir, username, 'setup-gocryptfs-workspace') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    gocryptfs -init "#{encrypted_dir}"
  BASH
end
