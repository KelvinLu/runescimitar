#
# Cookbook:: rpi4_server
# Recipe:: i3_config
#
# Copyright:: 2022, The Authors, All Rights Reserved.

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

config_dir = File.join(operator_home, '.config', 'i3')

directory config_dir do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

cookbook_file File.join(config_dir, 'config') do
  source 'i3_config'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

cookbook_file File.join(config_dir, 'conky') do
  source 'conky'

  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

cookbook_file File.join(config_dir, 'conkyrc') do
  source 'conkyrc'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

cookbook_file File.join(config_dir, 'urxvt-focused-cwd') do
  source 'urxvt-focused-cwd'

  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end
