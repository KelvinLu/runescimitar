#
# Cookbook:: lightning_node
# Recipe:: personal_user_litd
#

params   = node['persona'].fetch('personal_user')
username = params.fetch('name')

group 'lightning-terminal' do
  append true
  members [username]

  action :modify
end

file File.join(Dir.home(username), 'lit-cli') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    litcli --rpcserver=localhost:8443 --tlscertpath=/var/lightning-terminal/.lit/tls.cert --macaroonpath=/var/lightning-terminal/macaroon/lit.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lit-loop') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    loop --rpcserver=localhost:8443 --tlscertpath=/var/lightning-terminal/.lit/tls.cert --macaroonpath=/var/lightning-terminal/macaroon/loop.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lit-pool') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    pool --rpcserver=localhost:8443 --tlscertpath=/var/lightning-terminal/.lit/tls.cert --macaroonpath=/var/lightning-terminal/macaroon/pool.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lit-faraday') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    frcli --rpcserver=localhost:8443 --tlscertpath=/var/lightning-terminal/.lit/tls.cert --macaroonpath=/var/lightning-terminal/.faraday/mainnet/faraday.macaroon "$@"
  BASH
end

