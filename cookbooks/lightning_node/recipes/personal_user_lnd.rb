#
# Cookbook:: lightning_node
# Recipe:: personal_user_lnd
#

params   = node['bitcoin_users'].fetch('personal_user')
username = params.fetch('name')

group 'lnd' do
  append true
  members [username]

  action :modify
end

link File.join(Dir.home(username), '.lnd') do
  to '/var/lnd/.lnd'
end

sudo '50-lnd-personal-user' do
  user username

  commands [
    '/usr/local/bin/lnd',
    '/usr/bin/rview -T xterm /var/lnd/.lnd/logs/bitcoin/mainnet/lnd.log',
    '/usr/bin/tail -n50 -f /var/lnd/.lnd/logs/bitcoin/mainnet/lnd.log',
  ]
  runas 'lnd:lnd'
end

sudo '55-lnd-service-personal-user' do
  user username

  commands [
    '/usr/bin/systemctl start lnd.service',
    '/usr/bin/systemctl stop lnd.service',
  ]
end

sudo '56-lnd-tor-personal-user' do
  user username

  commands [
    '/usr/bin/cat /var/lib/tor/hidden_service_lnd_rest/hostname',
  ]
end

file File.join(Dir.home(username), 'run-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo -u lnd -g lnd lnd
  BASH
end

file File.join(Dir.home(username), 'start-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo systemctl start lnd.service
  BASH
end

file File.join(Dir.home(username), 'stop-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo systemctl stop lnd.service
  BASH
end

file File.join(Dir.home(username), 'status-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl status lnd.service
  BASH
end

file File.join(Dir.home(username), 'examine-logs-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo -u lnd -g lnd rview -T xterm /var/lnd/.lnd/logs/bitcoin/mainnet/lnd.log
  BASH
end

file File.join(Dir.home(username), 'follow-logs-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo -u lnd -g lnd tail -n50 -f /var/lnd/.lnd/logs/bitcoin/mainnet/lnd.log
  BASH
end

file File.join(Dir.home(username), 'lncli-admin') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lncli --macaroonpath /var/lnd/macaroon/admin.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lncli-readonly') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lncli --macaroonpath /var/lnd/macaroon/readonly.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lncli-invoice') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lncli --macaroonpath /var/lnd/macaroon/invoice.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'unlock-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lncli unlock -stdin
  BASH
end

file File.join(Dir.home(username), 'view-lnd-rest-onion-hostname') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo cat /var/lib/tor/hidden_service_lnd_rest/hostname
  BASH
end
