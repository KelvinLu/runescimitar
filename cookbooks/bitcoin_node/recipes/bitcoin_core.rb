#
# Cookbook:: bitcoin_node
# Recipe:: bitcoin_core
#

alternate_blocksdir_location = node['bitcoin_node']&.[]('blocksdir_location')

include_recipe 'rpi4_server::tor'

user 'bitcoin' do
  system true
  home '/var/bitcoin'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'debian-tor' do
  append true
  members %w[bitcoin]

  action :modify
end

directory '/var/bitcoin' do
  group lazy { Etc.getpwnam('bitcoin').gid }
  mode '0751'
end

directory '/var/bitcoin/datadir' do
  owner lazy { Etc.getpwnam('bitcoin').uid }
  group lazy { Etc.getpwnam('bitcoin').gid }
  mode '0751'
end

if alternate_blocksdir_location.nil?
  directory '/var/bitcoin/blocksdir' do
    owner lazy { Etc.getpwnam('bitcoin').uid }
    group lazy { Etc.getpwnam('bitcoin').gid }
    mode '0751'
  end
else
  directory File.join(alternate_blocksdir_location, 'blocksdir') do
    owner lazy { Etc.getpwnam('bitcoin').uid }
    group lazy { Etc.getpwnam('bitcoin').gid }
    mode '0751'
  end

  link '/var/bitcoin/blocksdir' do
    to File.join(alternate_blocksdir_location, 'blocksdir')
  end
end

include_recipe 'bitcoin_node::bitcoin_core_installation'
include_recipe 'bitcoin_node::bitcoin_configuration'
include_recipe 'bitcoin_node::bitcoin_operator'
