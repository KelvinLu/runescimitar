#
# Cookbook:: persona
# Recipe:: guest_user_wallet
#

[
  node['persona'].fetch('personal_user', nil),
  node['persona'].fetch('guest_user', nil)
].compact.each do |params|
  username = params.fetch('name')

  directory File.join(Dir.home(username), '.sparrow') do
    user lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'
  end

  link File.join(Dir.home(username), '.sparrow', 'wallets') do
    to File.join(Dir.home(username), 'workspace')
  end

  cookbook_file File.join(Dir.home(username), '.sparrow', 'config') do
    source 'sparrow-config'

    user lazy { Etc.getpwnam(username).uid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0600'

    action :create_if_missing
  end
end
