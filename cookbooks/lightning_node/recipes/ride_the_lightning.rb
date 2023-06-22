#
# Cookbook:: lightning_node
# Recipe:: ride_the_lightning
#
# Copyright:: 2022, The Authors, All Rights Reserved.

GITHUB_RTL_ARCHIVE_URL = Proc.new { |version| "https://github.com/Ride-The-Lightning/RTL/archive/refs/tags/v#{version}.tar.gz" }
GITHUB_RTL_SIGNATURE_URL = Proc.new { |version| "https://github.com/Ride-The-Lightning/RTL/releases/download/v#{version}/v#{version}.tar.gz.asc" }

GPG_KEY_SAUBYK_URL = 'https://keybase.io/suheb/pgp_keys.asc'

params            = node['lightning_node'].fetch('ride_the_lightning')
operator_user     = node['rpi4_server'].fetch('operator_user')

rtl_version       = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')
qualified_name    = "RTL-#{rtl_version}"
var_opt_directory = File.join('/var/opt/ride-the-lightning', "v#{rtl_version}")

include_recipe 'lightning_node::lnd'
include_recipe 'lightning_node::lightning_terminal'
include_recipe 'rpi4_server::nginx'
include_recipe 'rpi4_server::ufw'
include_recipe 'applications::nodejs'

user 'ride-the-lightning' do
  system true
  home '/var/ride-the-lightning'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'lnd' do
  append true
  members %w[ride-the-lightning]

  action :modify
end

directory '/var/ride-the-lightning' do
  group lazy { Etc.getpwnam('ride-the-lightning').gid }
  mode '0751'
end

directory '/var/ride-the-lightning/db' do
  user lazy { Etc.getpwnam('ride-the-lightning').uid }
  group lazy { Etc.getpwnam('ride-the-lightning').gid }
  mode '0751'
end

directory '/var/opt/ride-the-lightning' do
  user lazy { Etc.getpwnam('ride-the-lightning').uid }
  group lazy { Etc.getpwnam('ride-the-lightning').gid }
  mode '0755'
end

remote_file '/var/opt/ride-the-lightning/saubyk-gpg-key.asc' do
  source GPG_KEY_SAUBYK_URL

  mode '0644'

  checksum sha256_checksums.fetch('saubyk_gpg_key')
end

execute 'operator user gpg import (ride the lightning)' do
  command %w[gpg --import /var/opt/ride-the-lightning/saubyk-gpg-key.asc]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (ride the lightning)]', :immediate

  not_if { File.exist?('/var/opt/ride-the-lightning/.skip-gpg-import-chef') }
end

file 'skip operator user gpg import (ride the lightning)' do
  path '/var/opt/ride-the-lightning/.skip-gpg-import-chef'

  action :nothing
end

directory var_opt_directory do
  user lazy { Etc.getpwnam('ride-the-lightning').uid }
  group lazy { Etc.getpwnam('ride-the-lightning').gid }
  mode '0755'
end

remote_file File.join(var_opt_directory, File.basename(GITHUB_RTL_ARCHIVE_URL.call(rtl_version))) do
  source GITHUB_RTL_ARCHIVE_URL.call(rtl_version)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

remote_file File.join(var_opt_directory, File.basename(GITHUB_RTL_SIGNATURE_URL.call(rtl_version))) do
  source GITHUB_RTL_SIGNATURE_URL.call(rtl_version)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz_sig')
end

execute 'gpg verify archive signature (ride the lightning)' do
  command [*%w[gpg --verify], "v#{rtl_version}.tar.gz.asc", "v#{rtl_version}.tar.gz"]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user

  action :nothing
end

execute 'extract ride the lightning archive' do
  command [
    'tar',
    '-xvf', File.join(var_opt_directory, File.basename(GITHUB_RTL_ARCHIVE_URL.call(rtl_version))),
    '-C', var_opt_directory
  ]

  only_if {
    extract_dir = File.join(var_opt_directory, qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  notifies :run, 'execute[gpg verify archive signature (ride the lightning)]', :before
end

directory '/var/ride-the-lightning/.npm-cache' do
  user lazy { Etc.getpwnam('ride-the-lightning').uid }
  group lazy { Etc.getpwnam('ride-the-lightning').gid }
  mode '0755'
end

execute 'bind mount /var/opt/ride-the-lightning' do
  command %w[mount --bind /var/opt/ride-the-lightning /var/opt/ride-the-lightning]

  only_if { `findmnt -nlf -o options -T /var/opt/ride-the-lightning`.strip.split(',').include?('noexec') }

  notifies :run, 'execute[unmount /var/opt/ride-the-lightning]', :delayed

  creates '/var/ride-the-lightning/.skip-build-chef'
end

execute 'remount /var/opt/ride-the-lightning without noexec' do
  command %w[mount -o remount,bind,exec,nosuid,nodev /var/opt/ride-the-lightning]

  only_if { `findmnt -nlf -o options -T /var/opt/ride-the-lightning`.strip.split(',').include?('noexec') }

  creates '/var/ride-the-lightning/.skip-build-chef'
end

execute 'unmount /var/opt/ride-the-lightning' do
  command %w[umount /var/opt/ride-the-lightning]

  action :nothing
end

execute 'npm install (ride the lightning)' do
  command %w[npm install --cache /var/ride-the-lightning/.npm-cache --omit dev --legacy-peer-deps]
  cwd File.join(var_opt_directory, qualified_name)
  user 'ride-the-lightning'

  creates '/var/ride-the-lightning/.skip-build-chef'
end

file '/var/ride-the-lightning/.skip-build-chef' do
  action :create_if_missing
end

link '/var/ride-the-lightning/installation' do
  to File.join(var_opt_directory, qualified_name)
end

ruby_block 'check multipass file' do
  block do
    unless File.exist?('/var/ride-the-lightning/.multipass.txt') && !File.zero?('/var/ride-the-lightning/.multipass.txt')
      raise 'A UI password must be set in a file located at ~ride-the-lightning/.multipass.txt'
    end

    unless File.stat('/var/ride-the-lightning/.multipass.txt').mode & 07777 == 0600
      raise '.multipass.txt must have file permissions of 0600'
    end

    unless File.stat('/var/ride-the-lightning/.multipass.txt').uid == Etc.getpwnam('ride-the-lightning').uid
      raise '.multipass.txt must owned by user ride-the-lightning'
    end
  end
end

template File.join(var_opt_directory, qualified_name, 'RTL-Config.json') do
  source 'RTL-Config.json.erb'
  sensitive true

  variables lazy {
    multipass = File.read('/var/ride-the-lightning/.multipass.txt').strip
    local_node_alias = File.read('/var/lnd/.node-alias.txt').strip

    { multipass: multipass, local_node_alias: local_node_alias }
  }

  action :create_if_missing

  user lazy { Etc.getpwnam('ride-the-lightning').uid }
  group lazy { Etc.getpwnam('ride-the-lightning').gid }

  mode '0600'
end

cookbook_file '/etc/systemd/system/rtl.service' do
  source 'rtl.service'

  mode '0644'
end

systemd_unit 'rtl.service' do
  action :enable
end

cookbook_file '/etc/nginx/streams-enabled/rtl-reverse-proxy.conf' do
  source 'rtl-reverse-proxy.conf'

  mode '0644'

  notifies :run, 'execute[nginx test configuration]', :immediate
  notifies :restart, 'systemd_unit[nginx.service]', :delayed
end

execute 'ufw allow ride the lightning connection' do
  command [*%w[ufw allow from 192.168.0.0/16 to any port 4001 proto tcp comment], 'Allow Ride The Lightning']

  not_if do
    `ufw status verbose | grep -q '4001/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end
