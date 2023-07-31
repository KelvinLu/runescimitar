#
# Cookbook:: lightning_node
# Recipe:: personal_user_scrying_orb
#

params   = node['persona'].fetch('personal_user')
username = params.fetch('name')

directory File.join(Dir.home(username), '.scrying-orb') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'
end

file File.join(Dir.home(username), 'run-scrying-orb') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    CONFIGURATION_DIR=~/.scrying-orb scrying-orb "$@"
  BASH
end

file File.join(Dir.home(username), '.scrying-orb', 'lncli.yaml') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~YAML
    ---
    options:
      - '--macaroonpath=/var/lnd/macaroon/readonly.macaroon'
  YAML
end
