#
# Cookbook:: lightning_node
# Recipe:: lightning_terminal
#

alternate_datadir_location = node['lightning_node']&.[]('lnd_datadir_location')
neutrino_mode              = !(node['lightning_node'].fetch('lnd')['neutrino_mode'].nil?)

include_recipe 'lightning_node::lnd'

user 'lightning-terminal' do
  system true
  home '/var/lightning-terminal'
  shell '/usr/sbin/nologin'

  manage_home false
end

unless neutrino_mode
  group 'bitcoin' do
    append true
    members %w[lightning-terminal]

    action :modify
  end
end

group 'lnd' do
  append true
  members %w[lightning-terminal]

  action :modify
end

directory '/var/lightning-terminal' do
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

directory '/var/lightning-terminal/macaroon' do
  user lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

outer_dir =
  if alternate_datadir_location.nil?
    '/var/lightning-terminal/datadir'
  else
    File.join(alternate_datadir_location, 'datadir')
  end

directory File.join(outer_dir) do
  owner lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

directory File.join(outer_dir, 'lit') do
  owner lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

directory File.join(outer_dir, 'loop') do
  owner lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

directory File.join(outer_dir, 'pool') do
  owner lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

directory File.join(outer_dir, 'faraday') do
  owner lazy { Etc.getpwnam('lightning-terminal').uid }
  group lazy { Etc.getpwnam('lightning-terminal').gid }
  mode '0751'
end

link '/var/lightning-terminal/.lnd' do
  to '/var/lnd/.lnd'
end

link '/var/lightning-terminal/.lit' do
  to File.join(outer_dir, 'lit')
end

link '/var/lightning-terminal/.loop' do
  to File.join(outer_dir, 'loop')
end

link '/var/lightning-terminal/.pool' do
  to File.join(outer_dir, 'pool')
end

link '/var/lightning-terminal/.faraday' do
  to File.join(outer_dir, 'faraday')
end

include_recipe 'lightning_node::lightning_terminal_installation'
include_recipe 'lightning_node::lightning_terminal_configuration'
