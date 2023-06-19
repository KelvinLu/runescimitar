#
# Cookbook:: bitcoin_users
# Recipe:: guest_user_wallet
#
# Copyright:: 2022, The Authors, All Rights Reserved.

root_location = node['bitcoin_users'].fetch('root_location', '/home')

[
  node['bitcoin_users'].fetch('personal_user'),
  node['bitcoin_users'].fetch('guest_user')
].each do |params|
  username = params.fetch('name')

  home_dir = File.join(root_location, username, 'home/', username)

  directory File.join(home_dir, '.sparrow') do
    user lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'
  end

  link File.join(home_dir, '.sparrow', 'wallets') do
    to File.join(home_dir, 'workspace')
  end

  cookbook_file File.join(home_dir, '.sparrow', 'config') do
    source 'sparrow-config'

    user lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0600'

    action :create_if_missing
  end
end
