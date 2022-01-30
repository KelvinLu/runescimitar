#
# Cookbook:: applications
# Recipe:: vim_plug_install
#
# Copyright:: 2022, The Authors, All Rights Reserved.

require 'etc'

node['applications']&.[]('vim_plug_install')&.[]('users').each do |user|
  home_dir =
    begin
      Dir.home(user)
    rescue ArgumentError => e
      log 'no home directory' do
        message "Could not find home directory for user #{user}: #{e}"
        level   :error
      end

      next
    end

  vim_rc        = File.join(home_dir, '.vimrc')
  runtime_dir   = File.join(home_dir, '.vim')
  autoload_dir  = File.join(home_dir, '.vim', 'autoload')
  plugin_dir    = File.join(home_dir, '.vim', 'plugged')

  directory autoload_dir do
    recursive true

    owner     user
    group     Etc.getpwnam(user)[:gid]
    mode      '0755'
    action    :create
  end

  directory plugin_dir do
    recursive true

    owner     user
    group     Etc.getpwnam(user)[:gid]
    mode      '0755'
    action    :create
  end

  remote_file File.join(autoload_dir, 'plug.vim') do
    source    'https://raw.githubusercontent.com/junegunn/vim-plug/0.11.0/plug.vim'
    checksum  '0d4dc422c3151ff651063b251933b3465714c5b9f3226faf0ca7f8b4a440a552'

    owner   user
    group   Etc.getpwnam(user)[:gid]
    mode    '0644'
    action  :create_if_missing
  end

  log 'no .vimrc' do
    message "Could not find ~/.vimrc for user #{user}"
    level   :error

    not_if  { File.file?(vim_rc) }
  end

  execute "vim-plug install for user #{user}" do
    command     ['vim', '-e', '-s', '--cmd', "set rtp+=#{runtime_dir}", '-u', vim_rc, '-i', 'NONE', '+PlugInstall', '+PlugClean', '+qall']
    environment ({ 'HOME' => home_dir })
    user        user
    group       Etc.getpwnam(user)[:gid]

    only_if { File.file?(vim_rc) }
  end
end
