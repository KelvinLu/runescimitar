#
# Cookbook:: lightning_node
# Recipe:: charge_lnd_systemd
#

params    = node['bitcoin_users'].fetch('personal_user')
username  = params.fetch('name')

include_recipe 'lightning_node::charge_lnd'
include_recipe 'lightning_node::personal_user'

directory File.join(Dir.home(username), 'charge-lnd-logs') do
  user lazy { Etc.getpwnam(username).uid }
  mode '0751'
end

directory File.join(Dir.home(username), '.config') do
  mode '0755'
end

directory File.join(Dir.home(username), '.config', 'systemd') do
  mode '0755'
end

directory File.join(Dir.home(username), '.config', 'systemd', 'user') do
  mode '0755'
end

template File.join(Dir.home(username), '.config', 'systemd', 'user', 'charge-lnd@.service') do
  source 'charge-lnd@.service.erb'

  variables(
    log_file: File.join(Dir.home(username), 'charge-lnd-logs', 'charge-lnd.log')
  )

  mode '0644'
end

cookbook_file File.join(Dir.home(username), '.config', 'systemd', 'user', 'charge-lnd@.timer') do
  source 'charge-lnd@.timer'

  mode '0644'
end

file File.join(Dir.home(username), 'start-timer-charge-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl --user start "$(systemd-escape --template charge-lnd@.timer --path "$@")"
  BASH
end

file File.join(Dir.home(username), 'stop-timer-charge-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl --user stop "$(systemd-escape --template charge-lnd@.timer --path "$@")"
  BASH
end

file File.join(Dir.home(username), 'show-timer-charge-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl --user list-timers "$(systemd-escape --template charge-lnd@.timer --path "$@")"
  BASH
end

file File.join(Dir.home(username), 'show-status-charge-lnd') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    systemctl --user status "$(systemd-escape --template charge-lnd@.service --path "$@")"
  BASH
end

template '/etc/logrotate.d/charge-lnd-log' do
  source 'charge-lnd-log_logrotate.erb'

  variables(
    log_file: File.join(Dir.home(username), 'charge-lnd-logs', 'charge-lnd.log'),
    user: username
  )

  mode '0644'
end
