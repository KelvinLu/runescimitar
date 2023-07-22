#
# Cookbook:: lightning_node
# Recipe:: personal_user_lnd_scb
#

params   = node['persona'].fetch('personal_user')
username = params.fetch('name')

sudo '57-lnd-scb-personal-user' do
  user username

  commands [
    '/usr/bin/systemctl start lnd-scb.service',
    '/usr/bin/systemctl stop lnd-scb.service',
  ]
end

file File.join(Dir.home(username), 'start-lnd-scb') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo systemctl start lnd-scb.service
  BASH
end

file File.join(Dir.home(username), 'stop-lnd-scb') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    sudo systemctl stop lnd-scb.service
  BASH
end

file File.join(Dir.home(username), 'status-lnd-scb') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl status lnd-scb.service
  BASH
end
