#
# Cookbook:: lightning_node
# Recipe:: personal_user_rebalance_lnd
#

params   = node['bitcoin_users'].fetch('personal_user')
username = params.fetch('name')

file File.join(Dir.home(username), 'run-rebalance-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    rebalance-lnd --lnddir /var/rebalance-lnd/.lnd "$@"
  BASH
end
