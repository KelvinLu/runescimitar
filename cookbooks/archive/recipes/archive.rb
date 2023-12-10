#
# Cookbook:: archive
# Recipe:: archive
#

include_recipe 'archive::archive_users'
include_recipe 'archive::imp_box'

node['archive']&.[]('users')&.each do |username, user_home_dir|
  link File.join(Dir.home(username), 'run-imp-box') do
    to '/opt/imp-box/run-imp-box'
  end

  link File.join(Dir.home(username), 'dry-run-imp-box') do
    to '/opt/imp-box/dry-run-imp-box'
  end

  directory File.join(Dir.home(username), 'imp-box') do
    user lazy { Etc.getpwnam(username).gid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'
  end

  directory File.join(Dir.home(username), 'data') do
    user lazy { Etc.getpwnam(username).gid }
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'
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

  link File.join(Dir.home(username), '.config', 'systemd', 'user', 'imp-box@.service') do
    to '/opt/imp-box/imp-box@.service'
  end

  link File.join(Dir.home(username), '.config', 'systemd', 'user', 'imp-box@.timer') do
    to '/opt/imp-box/imp-box@.timer'
  end

  file File.join(Dir.home(username), 'start-timer-imp-box') do
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'

    content <<~BASH
      #!/bin/bash
      systemctl --user start "$(systemd-escape --template imp-box@.timer --path "$@")"
    BASH
  end

  file File.join(Dir.home(username), 'stop-timer-imp-box') do
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'

    content <<~BASH
      #!/bin/bash
      systemctl --user stop "$(systemd-escape --template imp-box@.timer --path "$@")"
    BASH
  end

  file File.join(Dir.home(username), 'show-timer-imp-box') do
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'

    content <<~BASH
      #!/bin/bash
      systemctl --user list-timers "$(systemd-escape --template imp-box@.timer --path "$@")"
    BASH
  end

  file File.join(Dir.home(username), 'show-status-imp-box') do
    group lazy { Etc.getpwnam(username).gid }
    mode '0750'

    content <<~BASH
      #!/bin/bash
      systemctl --user status "$(systemd-escape --template imp-box@.service --path "$@")"
    BASH
  end
end
