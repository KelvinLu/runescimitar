#
# Cookbook:: rpi4_server
# Recipe:: vim
#
# Copyright:: 2022, The Authors, All Rights Reserved.

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

directory File.join(operator_home, '.vim') do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

directory File.join(operator_home, '.vim', 'colors') do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

cookbook_file File.join(operator_home, '.vimrc') do
  source '.vimrc'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

cookbook_file File.join(operator_home, '.vim', 'colors', 'wombat256mod.vim') do
  source 'wombat256mod.vim'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

include_recipe 'applications::vim_plug_install'
