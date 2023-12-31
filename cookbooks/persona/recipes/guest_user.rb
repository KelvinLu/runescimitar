#
# Cookbook:: persona
# Recipe:: guest_user
#

root_location = node['persona'].fetch('root_location', '/home')
params        = node['persona'].fetch('guest_user')
username      = params.fetch('name')

outer_home_dir  = File.join(root_location, username)
inner_home_dir  = File.join(outer_home_dir, 'home')
user_home_dir   = File.join(inner_home_dir, username)
user_bin_dir    = File.join(user_home_dir, '.bin')

login_shell     = File.join('/home/.login-shell/', username)

i3_config_dir   = File.join(user_home_dir, '.config', 'i3')
vim_colors_dir  = File.join(user_home_dir, '.vim', 'colors')

user username do
  home user_home_dir
  shell login_shell

  manage_home false
end

directory outer_home_dir do
  mode '0751'
end

directory inner_home_dir do
  mode '0751'
end

directory user_home_dir do
  group lazy { Etc.getpwnam(username).gid }
  mode '0751'
end

directory File.dirname(login_shell) do
  mode '0755'
end

cookbook_file login_shell do
  source 'login-shell'

  group lazy { Etc.getpwnam(username).gid }
  mode '0750'
end

cookbook_file File.join(user_home_dir, '.bash_profile') do
  source '.bash_profile_guest'

  mode '0644'
end

cookbook_file File.join(user_home_dir, '.bash_logout') do
  source '.bash_logout_guest'

  mode '0644'
end

cookbook_file File.join(user_home_dir, '.bashrc') do
  source '.bashrc_guest'

  mode '0644'
end

cookbook_file File.join(user_home_dir, '.Xresources') do
  source '.Xresources_guest'

  mode '0644'
end

directory File.dirname(i3_config_dir) do
  mode '0755'
end

directory i3_config_dir do
  mode '0755'
end

template File.join(i3_config_dir, 'config') do
  source 'i3_config_guest.erb'

  variables(
    spellbook_message: params.fetch('spellbook', []).map { |spell| "(#{spell.fetch('bindsym')}) #{spell.fetch('label')}" }.join(' ~ '),
    spells: params.fetch('spellbook', []).map { |spell| [spell.fetch('bindsym'), spell.fetch('command')] }
  )

  mode '0644'
end

cookbook_file File.join(i3_config_dir, 'conky') do
  source 'conky'

  mode '0755'
end

cookbook_file File.join(i3_config_dir, 'conkyrc') do
  source 'conkyrc'

  mode '0644'
end

directory File.dirname(vim_colors_dir) do
  mode '0755'
end

directory vim_colors_dir do
  mode '0755'
end

cookbook_file File.join(user_home_dir, '.vimrc') do
  source '.vimrc'

  mode '0644'
end

cookbook_file File.join(vim_colors_dir, 'wombat256mod.vim') do
  source 'wombat256mod.vim'

  mode '0644'
end

cookbook_file File.join(user_home_dir, '.shadow-wizard-money-gang.txt') do
  source 'shadow-wizard-money-gang.txt'

  mode '0644'
end

cookbook_file File.join(user_home_dir, '.wizard-kaomoji') do
  source 'wizard-kaomoji.bash'

  mode '0644'
end

include_recipe 'persona::guest_user_bin'
include_recipe 'persona::guest_user_workspace'
