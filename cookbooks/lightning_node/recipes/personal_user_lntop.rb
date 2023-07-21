#
# Cookbook:: lightning_node
# Recipe:: personal_user_lntop
#

params   = node['bitcoin_users'].fetch('personal_user')
username = params.fetch('name')

directory File.join(Dir.home(username), '.lntop') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0751'
end

file File.join(Dir.home(username), '.lntop', 'lntop.log') do
  user lazy { Etc.getpwnam(username).uid }
  group lazy { Etc.getpwnam(username).gid }

  mode '0640'

  action :create_if_missing
end

cookbook_file File.join(Dir.home(username), '.lntop', 'config.toml') do
  source 'lntop-config.toml'

  user lazy { Etc.getpwnam(username).uid }
  group lazy { Etc.getpwnam(username).gid }
  mode '0640'

  action :create_if_missing
end

