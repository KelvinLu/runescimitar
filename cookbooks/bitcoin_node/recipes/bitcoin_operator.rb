#
# Cookbook:: bitcoin_node
# Recipe:: bitcoin_operator
#

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

link File.join(operator_home, '.bitcoin') do
  to '/var/bitcoin/datadir'

  owner operator_user.uid
  group operator_user.gid
end

group 'bitcoin' do
  append true
  members [operator_user.name]

  action :modify
end
