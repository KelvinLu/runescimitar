#
# Cookbook:: bitcoin_node
# Recipe:: libbitcoin_explorer
#
# Copyright:: 2022, The Authors, All Rights Reserved.

git_ref = node['bitcoin_node'].fetch('libbitcoin_explorer').fetch('git_ref')

include_recipe 'applications::cpp_build_tools'

directory '/opt/libbitcoin-explorer' do
  mode '0755'
end

directory '/var/opt/libbitcoin-explorer' do
  mode '0755'
end

git '/var/opt/libbitcoin-explorer' do
  repository 'https://github.com/libbitcoin/libbitcoin-explorer.git'
  revision git_ref
  depth 1

  only_if { Dir.empty?('/var/opt/libbitcoin-explorer') }
end

execute 'bind mount /var/opt/libbitcoin-explorer' do
  command %w[mount --bind /var/opt/libbitcoin-explorer /var/opt/libbitcoin-explorer]

  only_if { `findmnt -nlf -o options -T /var/opt/libbitcoin-explorer`.strip.split(',').include?('noexec') }

  notifies :run, 'execute[unmount /var/opt/libbitcoin-explorer]', :delayed

  creates '/opt/libbitcoin-explorer/bin/bx'
end

execute 'remount /var/opt/libbitcoin-explorer without noexec' do
  command %w[mount -o remount,bind,exec,nosuid,nodev /var/opt/libbitcoin-explorer]

  only_if { `findmnt -nlf -o options -T /var/opt/libbitcoin-explorer`.strip.split(',').include?('noexec') }

  creates '/opt/libbitcoin-explorer/bin/bx'
end

execute 'unmount /var/opt/libbitcoin-explorer' do
  command %w[umount /var/opt/libbitcoin-explorer]

  action :nothing
end

execute 'build libbitcoin-explorer' do
  command %w[./install.sh --with-icu --build-icu --build-boost --build-zmq --prefix=/opt/libbitcoin-explorer]
  cwd '/var/opt/libbitcoin-explorer'
  environment({
    'CPPFLAGS' => '-w'
  })

  timeout 21600

  creates '/opt/libbitcoin-explorer/bin/bx'
end

link '/usr/local/bin/bx' do
  to '/opt/libbitcoin-explorer/bin/bx'
end
