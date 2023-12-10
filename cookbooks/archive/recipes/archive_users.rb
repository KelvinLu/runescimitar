#
# Cookbook:: archive
# Recipe:: archive_users
#

node['archive']&.[]('users')&.each do |username, user_home_dir|
  i3_config_dir   = File.join(user_home_dir, '.config', 'i3')
  vim_colors_dir  = File.join(user_home_dir, '.vim', 'colors')

  user username do
    home user_home_dir
    shell '/bin/bash'

    manage_home false
  end

  directory user_home_dir do
    user lazy { Etc.getpwnam(username).gid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0751'
  end

  cookbook_file File.join(user_home_dir, '.inputrc') do
    source '.inputrc'

    mode '0644'
  end

  cookbook_file File.join(user_home_dir, '.bashrc') do
    source '.bashrc'

    mode '0644'
  end

  cookbook_file File.join(user_home_dir, '.Xresources') do
    source '.Xresources'

    mode '0644'
  end

  directory File.dirname(i3_config_dir) do
    mode '0755'
  end

  directory i3_config_dir do
    mode '0755'
  end

  cookbook_file File.join(i3_config_dir, 'config') do
    source 'i3_config'

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

  directory File.join(user_home_dir, '.ssh') do
    mode '0755'
  end

  file File.join(user_home_dir, '.ssh', 'authorized_keys') do
    owner lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0600'

    action :create_if_missing
  end

  directory File.join(user_home_dir, '.gnupg') do
    owner lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0700'
  end

  file File.join(user_home_dir, '.gnupg', 'gpg.conf') do
    content <<~CONF
      pinentry-mode loopback
    CONF

    owner lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0600'
  end
end
