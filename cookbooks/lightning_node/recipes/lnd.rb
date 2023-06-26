#
# Cookbook:: lightning_node
# Recipe:: lnd
#

alternate_datadir_location = node['lightning_node']&.[]('lnd_datadir_location')

datadir =
  if alternate_datadir_location.nil?
    '/var/lnd/datadir'
  else
    File.join(alternate_datadir_location, 'lnd', 'datadir')
  end

include_recipe 'bitcoin_node::bitcoin_core'
include_recipe 'rpi4_server::tor'

user 'lnd' do
  system true
  home '/var/lnd'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'bitcoin' do
  append true
  members %w[lnd]

  action :modify
end

group 'debian-tor' do
  append true
  members %w[lnd]

  action :modify
end

directory '/var/lnd' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/lnd/.lnd' do
  owner lazy { Etc.getpwnam('lnd').uid }
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/lnd/.scb' do
  owner lazy { Etc.getpwnam('lnd').uid }
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/lnd/macaroon' do
  owner lazy { Etc.getpwnam('lnd').uid }
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

unless alternate_datadir_location.nil?
  directory File.join(alternate_datadir_location, 'lnd') do
    owner lazy { Etc.getpwnam('lnd').uid }
    group lazy { Etc.getpwnam('lnd').gid }
    mode '0751'
  end
end

directory datadir do
  owner lazy { Etc.getpwnam('lnd').uid }
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

link '/var/lnd/.lnd/data' do
  to datadir
end

include_recipe 'lightning_node::lnd_installation'
include_recipe 'lightning_node::lnd_configuration'
