#
# Cookbook:: bitcoin_node
# Recipe:: bitcoin_configuration
#
# Copyright:: 2022, The Authors, All Rights Reserved.

remote_file 'bitcoin rpcauth script' do
  path '/var/bitcoin/rpcauth.py'
  source 'https://raw.githubusercontent.com/bitcoin/bitcoin/master/share/rpcauth/rpcauth.py'

  checksum node['bitcoin_node'].fetch('rpcauth_script_sha256')

  mode '0644'
end

directory '/var/bitcoin/.bitcoin' do
  group lazy { Etc.getpwnam('bitcoin').gid }

  mode '0750'
end

ruby_block 'check rpcauth file' do
  block do
    unless File.exist?('/var/bitcoin/.bitcoin/rpcauth.txt')
      raise 'rpcauth.txt must be generated (see rpcauth.py)'
    end
  end

  action :nothing
end

template '/var/bitcoin/.bitcoin/bitcoin.conf' do
  source 'bitcoin.conf.erb'

  variables lazy {
    rpcauth =
      if File.exist?('/var/bitcoin/.bitcoin/rpcauth.txt')
        File.read('/var/bitcoin/.bitcoin/rpcauth.txt').strip
      else
        '# rpcauth='
      end

    ibd_optimization = node['bitcoin_node'].fetch('initial_block_download') {
      ibd = currently_doing_initial_block_download?
      ibd.nil? ? true : ibd
    }

    ibd_dbcache_mb = node['bitcoin_node']&.[]('ibd_dbcache_mb')

    { rpcauth: rpcauth, ibd_optimization: ibd_optimization, ibd_dbcache_mb: ibd_dbcache_mb }
  }

  group lazy { Etc.getpwnam('bitcoin').gid }

  mode '0640'

  notifies :run, 'ruby_block[check rpcauth file]', :before
end

link '/var/bitcoin/datadir/bitcoin.conf' do
  to '/var/bitcoin/.bitcoin/bitcoin.conf'
end

file '/var/bitcoin/datadir/debug.log' do
  user lazy { Etc.getpwnam('bitcoin').uid }
  group lazy { Etc.getpwnam('bitcoin').gid }

  mode '0640'

  action :create_if_missing
end

cookbook_file '/etc/logrotate.d/bitcoind-debug-log' do
  source 'bitcoind-debug-log_logrotate'

  mode '0644'
end

template '/etc/systemd/system/bitcoind.service' do
  source 'bitcoind.service.erb'

  variables lazy {
    { after_units: node['bitcoin_node'].[]('service_require')&.[]('bitcoind.service') }
  }

  mode '0640'
end

systemd_unit 'bitcoind.service' do
  action :enable
end
