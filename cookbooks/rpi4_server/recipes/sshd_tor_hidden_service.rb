#
# Cookbook:: rpi4_server
# Recipe:: sshd_tor_hidden_service
#
# Copyright:: 2022, The Authors, All Rights Reserved.

include_recipe 'rpi4_server::tor'

ruby_block 'tor hidden service (sshd)' do
  block do
    node.override['rpi4_server']['tor']['hidden_services'] = [
      *node['rpi4_server']['tor']['hidden_services'],
      <<~TORRC
        # Hidden service (sshd)
        HiddenServiceDir /var/lib/tor/hidden_service_sshd/
        HiddenServiceVersion 3
        HiddenServicePort 22 127.0.0.1:22
      TORRC
    ]
  end

  notifies :create, 'template[/etc/tor/torrc]', :delayed
end
