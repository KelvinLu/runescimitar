#
# Cookbook:: lightning_node
# Recipe:: lnd_tor_hidden_service
#

include_recipe 'rpi4_server::tor'

ruby_block 'tor hidden service (lnd)' do
  block do
    node.override['rpi4_server']['tor']['hidden_services'] = [
      *node['rpi4_server']['tor']['hidden_services'],
      <<~TORRC
        # Hidden service (LND, REST)
        HiddenServiceDir /var/lib/tor/hidden_service_lnd_rest/
        HiddenServiceVersion 3
        HiddenServicePort 8080 127.0.0.1:8080
      TORRC
    ]
  end

  notifies :create, 'template[/etc/tor/torrc]', :delayed
end
