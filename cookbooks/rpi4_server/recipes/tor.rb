#
# Cookbook:: rpi4_server
# Recipe:: tor
#
# Copyright:: 2022, The Authors, All Rights Reserved.

TOR_PROJECT_GPG_KEY_URL = 'https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc'
SHA256_DIGEST_ASCII_ARMORED_KEY = '7b3fec7e6928ec67c6342a78ed9b2d647d034d0d01c9dd17864f4d7c04bf1347'

TOR_PROJECT_PUBKEY = '74A941BA219EC810'

lsb_release_codename = `lsb_release -c`.strip.delete_prefix("Codename:\t")

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))

node.default['rpi4_server']['tor']['hidden_services'] = []

apt_package 'apt-transport-https' do
  action :install
end

remote_file '/usr/share/keyrings/tor-project_A3C4F0F9.asc' do
  source TOR_PROJECT_GPG_KEY_URL

  mode '0644'

  checksum SHA256_DIGEST_ASCII_ARMORED_KEY
end

execute 'remove ascii armor encoding from key and place into /usr/share/keyrings' do
  command %w[gpg --batch --no-tty -o /usr/share/keyrings/tor-archive-keyring.gpg --dearmor /usr/share/keyrings/tor-project_A3C4F0F9.asc]

  creates '/usr/share/keyrings/tor-archive-keyring.gpg'
end

execute 'remove ascii armor encoding from key and place into /etc/apt/trusted.gpg.d' do
  command %w[gpg --batch --no-tty -o /etc/apt/trusted.gpg.d/tor-archive-keyring.gpg --dearmor /usr/share/keyrings/tor-project_A3C4F0F9.asc]

  creates '/etc/apt/trusted.gpg.d/tor-archive-keyring.gpg'
end

file '/etc/apt/sources.list.d/tor.list' do
  content <<~SOURCE_LIST
    deb     [arch=arm64 signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org #{lsb_release_codename} main
    deb-src [arch=arm64 signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org #{lsb_release_codename} main
  SOURCE_LIST

  notifies :run, 'execute[apt update]', :immediate
end

execute 'apt update' do
  command %w[apt update]

  action :nothing
end

apt_package 'tor' do
  action :install
end

apt_package 'deb.torproject.org-keyring' do
  action :install
end

template '/etc/tor/torrc' do
  source 'torrc.erb'

  variables lazy {
    { hidden_services_configuration: node['rpi4_server']['tor']['hidden_services'] }
  }

  mode '0644'

  notifies :restart, 'systemd_unit[tor.service]', :delayed
  notifies :create_if_missing, 'file[/etc/tor/.torrc-skip-first-edit-chef]', :immediate

  not_if { File.exist?('/etc/tor/.torrc-skip-first-edit-chef') && node['rpi4_server']['tor']['hidden_services'].empty? }
end

file '/etc/tor/.torrc-skip-first-edit-chef' do
  action :create_if_missing
end

systemd_unit 'tor.service' do
  action :nothing
end

apt_package 'nyx' do
  action :install
end

group 'debian-tor' do
  append true
  members [operator_user.name]

  action :modify
end
