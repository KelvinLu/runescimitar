#
# Cookbook:: bitcoin_node
# Recipe:: mempool
#
# Copyright:: 2022, The Authors, All Rights Reserved.

NODEJS_PACKAGE_ARCHIVE = 'https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-arm64.tar.xz'

git_ref = node['bitcoin_node'].fetch('mempool').fetch('git_ref')
server_name = node['name'] || 'localhost'

include_recipe 'rpi4_server::nginx'
include_recipe 'rpi4_server::ufw'
include_recipe 'rpi4_server::tor'
include_recipe 'bitcoin_node::btc_rpc_proxy'
include_recipe 'bitcoin_node::fulcrum'

apt_package 'mariadb-server' do
  action :install
end

apt_package 'mariadb-client' do
  action :install
end

user 'mempool' do
  system true
  home '/var/mempool'
  shell '/usr/sbin/nologin'

  manage_home false
end

directory '/var/mempool' do
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0751'
end

file '/var/mempool/.mariadb-password' do
  content lazy { `gpg --gen-random --armor 1 16`.strip }
  sensitive true

  user lazy { Etc.getpwnam('mempool').uid }
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0600'

  action :create_if_missing
end

file '/var/mempool/.bitcoind-password' do
  content lazy { `gpg --gen-random --armor 1 32`.strip }
  sensitive true

  user lazy { Etc.getpwnam('mempool').uid }
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0600'

  action :create_if_missing
end

execute 'set mysql password' do
  command lazy {
    password = File.read('/var/mempool/.mariadb-password')
    [*%w[mysql -u root -e], "create database mempool ; grant all privileges on mempool.* to 'mempool'@'localhost' identified by '#{password}' ;"]
  }
  sensitive true

  not_if { File.exist?('/var/mempool/.mariadb-initialized') }

  notifies :create, 'file[/var/mempool/.mariadb-initialized]', :immediate
end

file '/var/mempool/.mariadb-initialized' do
  action :nothing
end

template '/var/mempool/mempool-config.json' do
  source 'mempool-config.json.erb'
  sensitive true

  variables lazy {
    bitcoind_password = File.read('/var/mempool/.bitcoind-password')
    mariadb_password = File.read('/var/mempool/.mariadb-password')
    { bitcoind_password: bitcoind_password, mariadb_password: mariadb_password }
  }

  user lazy { Etc.getpwnam('mempool').uid }
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0600'
end

directory '/var/opt/nodejs' do
  mode '0755'
end

remote_file 'download nodejs' do
  path File.join('/var/opt/nodejs', File.basename(NODEJS_PACKAGE_ARCHIVE))
  source NODEJS_PACKAGE_ARCHIVE

  mode '0644'

  checksum 'c81dfa0bada232cb4583c44d171ea207934f7356f85f9184b32d0dde69e2e0ea'
end

execute 'install nodejs' do
  command [*%w[tar -C /usr/local --no-same-owner --strip-components 1 -xJf], File.join('/var/opt/nodejs', File.basename(NODEJS_PACKAGE_ARCHIVE))]

  creates '/usr/local/bin/node'

  notifies :create, 'remote_file[download nodejs]', :before
end

directory '/var/opt/mempool' do
  user lazy { Etc.getpwnam('mempool').uid }
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0755'
end

git '/var/opt/mempool' do
  repository 'https://github.com/mempool/mempool.git'
  revision git_ref
  depth 1

  user 'mempool'

  only_if { Dir.empty?('/var/opt/mempool') }
end

directory '/var/mempool/.npm-cache' do
  user lazy { Etc.getpwnam('mempool').uid }
  group lazy { Etc.getpwnam('mempool').gid }
  mode '0755'
end

execute 'bind mount /var/opt/mempool' do
  command %w[mount --bind /var/opt/mempool /var/opt/mempool]

  only_if { `findmnt -nlf -o options -T /var/opt/mempool`.strip.split(',').include?('noexec') }

  notifies :run, 'execute[unmount /var/opt/mempool]', :delayed

  creates '/var/mempool/.skip-build-chef'
end

execute 'remount /var/opt/mempool without noexec' do
  command %w[mount -o remount,bind,exec,nosuid,nodev /var/opt/mempool]

  only_if { `findmnt -nlf -o options -T /var/opt/mempool`.strip.split(',').include?('noexec') }

  creates '/var/mempool/.skip-build-chef'
end

execute 'unmount /var/opt/mempool' do
  command %w[umount /var/opt/mempool]

  action :nothing
end

execute 'npm install (mempool backend)' do
  command %w[npm install --cache /var/mempool/.npm-cache --prod]
  cwd '/var/opt/mempool/backend'
  user 'mempool'

  creates '/var/mempool/.skip-build-chef'
end

execute 'npm run build (mempool backend)' do
  command %w[npm run build --cache /var/mempool/.npm-cache]
  cwd '/var/opt/mempool/backend'
  user 'mempool'

  creates '/var/mempool/.skip-build-chef'
end

execute 'npm install (mempool frontend)' do
  command %w[npm install --cache /var/mempool/.npm-cache --prod]
  cwd '/var/opt/mempool/frontend'
  user 'mempool'

  creates '/var/mempool/.skip-build-chef'
end

execute 'npm run build (mempool frontend)' do
  command %w[npm run build --cache /var/mempool/.npm-cache]
  cwd '/var/opt/mempool/frontend'
  user 'mempool'

  creates '/var/mempool/.skip-build-chef'
end

file '/var/mempool/.skip-build-chef' do
  action :create_if_missing
end

link '/var/opt/mempool/backend/mempool-config.json' do
  to '/var/mempool/mempool-config.json'
end

execute 'ufw allow mempool connection' do
  command [*%w[ufw allow 4081/tcp comment], 'Allow Mempool']

  not_if do
    `ufw status verbose | grep -q '4081/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

directory '/var/www/mempool' do
  user lazy { Etc.getpwnam('www-data').uid }
  group lazy { Etc.getpwnam('www-data').gid }
  mode '0755'
end

execute 'rsync mempool frontend' do
  command %w[rsync -av --delete --no-p --no-g /var/opt/mempool/frontend/dist/mempool/ /var/www/mempool/]
  user 'www-data'
end

template '/etc/nginx/sites-available/mempool-ssl.conf' do
  source 'nginx_mempool-ssl.conf.erb'

  variables(
    server_name: server_name
  )
end

link '/etc/nginx/sites-enabled/mempool-ssl.conf' do
  to '/etc/nginx/sites-available/mempool-ssl.conf'
end

file '/etc/nginx/snippets/nginx-mempool.conf' do
  content File.read('/var/opt/mempool/nginx-mempool.conf')

  mode '0644'
end

systemd_unit 'nginx.service' do
  action :reload
end

cookbook_file '/etc/systemd/system/mempool.service' do
  source 'mempool.service'

  mode '0644'
end

systemd_unit 'mempool.service' do
  action :enable
end

ruby_block 'tor hidden service (mempool)' do
  block do
    node.override['rpi4_server']['tor']['hidden_services'] = [
      *node['rpi4_server']['tor']['hidden_services'],
      <<~TORRC
        # Hidden service (mempool)
        HiddenServiceDir /var/lib/tor/hidden_service_mempool/
        HiddenServiceVersion 3
        HiddenServicePort 4081 127.0.0.1:4081
      TORRC
    ]
  end

  notifies :create, 'template[/etc/tor/torrc]', :delayed
end
