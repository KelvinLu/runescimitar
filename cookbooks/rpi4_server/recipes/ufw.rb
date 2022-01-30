#
# Cookbook:: rpi4_server
# Recipe:: ufw
#
# Copyright:: 2022, The Authors, All Rights Reserved.

apt_package 'ufw' do
  action :install
end

execute 'ufw default deny incoming' do
  command %w[ufw default deny incoming]

  not_if do
    `ufw status verbose | grep 'Default:' | grep -q 'deny (incoming)'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw default allow outgoing' do
  command %w[ufw default allow outgoing]

  not_if do
    `ufw status verbose | grep 'Default:' | grep -q 'allow (outgoing)'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow ssh' do
  command %w[ufw allow ssh]

  not_if do
    `ufw status verbose | grep -q '22/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw logging low' do
  command %w[ufw logging low]

  not_if do
    `ufw status verbose | grep 'Logging:' | grep -q 'on (low)'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

systemd_unit 'ufw.service' do
  action :enable
end

execute 'ufw enable' do
  command 'yes | ufw enable'

  not_if { `ufw status`.lines.first.strip == 'Status: active' }
end

execute 'ufw reload' do
  command %w[ufw reload]

  action :nothing
end
