#
# Cookbook:: lightning_node
# Recipe:: personal_user_tinderbox
#

params   = node['persona'].fetch('personal_user')
username = params.fetch('name')

directory File.join(Dir.home(username), '.tinderbox') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'
end

file File.join(Dir.home(username), 'run-tinderbox') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    CONFIGURATION_DIR=~/.tinderbox tinderbox "$@"
  BASH
end

file File.join(Dir.home(username), '.tinderbox', 'litcli.yaml') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~YAML
    ---
    options:
      - '--rpcserver=localhost:8443'
      - '--tlscertpath=/var/lightning-terminal/.lit/tls.cert'
      - '--macaroonpath=/var/lightning-terminal/macaroon/lit.macaroon'
  YAML
end

file File.join(Dir.home(username), '.tinderbox', 'lncli.yaml') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~YAML
    ---
    options:
      - '--macaroonpath=/var/lnd/macaroon/admin.macaroon'
  YAML
end

link File.join(Dir.home(username), '.tinderbox', 'aliases.yaml') do
  to File.join(Dir.home(username), 'workspace', 'lnd-account-aliases.yaml')
end

link File.join(Dir.home(username), '.tinderbox', 'roles.yaml') do
  to '/opt/tinderbox/configuration/roles.yaml'
end
