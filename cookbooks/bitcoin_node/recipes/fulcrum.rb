#
# Cookbook:: bitcoin_node
# Recipe:: fulcrum
#

GITHUB_FULCRUM_RELEASES_URL = Proc.new { |version, filename| "https://github.com/cculianu/Fulcrum/releases/download/v#{version}/#{filename.call(version)}" }

ARCHIVE_FILENAME = Proc.new { |version| "Fulcrum-#{version}-arm64-linux.tar.gz" }
CHECKSUMS_FILENAME = Proc.new { |version| "Fulcrum-#{version}-shasums.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "Fulcrum-#{version}-shasums.txt.asc" }

GPG_KEY_CALIN_CULIANU_URL = 'https://raw.githubusercontent.com/Electron-Cash/keys-n-hashes/master/pubkeys/calinkey.txt'

params            = node['bitcoin_node'].fetch('fulcrum')
server_name       = node['name'] || 'localhost'
operator_user     = node['rpi4_server'].fetch('operator_user')

fulcrum_version   = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')

versioned_name    = "fulcrum-#{fulcrum_version}"
versioned_dir     = File.join('/var/opt/fulcrum', versioned_name)

include_recipe 'bitcoin_node::bitcoin_core'
include_recipe 'rpi4_server::ufw'
include_recipe 'rpi4_server::tor'

apt_package 'libssl-dev' do
  action :install
end

user 'fulcrum' do
  system true
  home '/var/fulcrum'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'bitcoin' do
  append true
  members %w[fulcrum]

  action :modify
end

directory '/var/fulcrum' do
  group lazy { Etc.getpwnam('fulcrum').gid }
  mode '0751'
end

directory '/var/fulcrum/datadir' do
  user lazy { Etc.getpwnam('fulcrum').uid }
  group lazy { Etc.getpwnam('fulcrum').gid }
  mode '0751'
end

link '/var/fulcrum/.fulcrum' do
  to 'datadir'
end

directory '/var/fulcrum/datadir/fulcrum_db' do
  user lazy { Etc.getpwnam('fulcrum').uid }
  group lazy { Etc.getpwnam('fulcrum').gid }
  mode '0751'
end

execute 'self-signed server certificate for fulcrum' do
  command %W[
    openssl req -x509 -newkey rsa:2048 -nodes
      -keyout fulcrum-ssl-key.pem
      -out fulcrum-ssl-cert.pem
      -subj /CN=#{server_name}_fulcrum
      -days 730
  ]
  cwd '/var/fulcrum'

  creates '/var/fulcrum/fulcrum-ssl-cert.pem'
end

file '/var/fulcrum/fulcrum-ssl-key.pem' do
  user lazy { Etc.getpwnam('fulcrum').uid }
  group lazy { Etc.getpwnam('fulcrum').gid }
end

file '/var/fulcrum/fulcrum-ssl-cert.pem' do
  user lazy { Etc.getpwnam('fulcrum').uid }
  group lazy { Etc.getpwnam('fulcrum').gid }
end

directory '/var/opt/fulcrum' do
  mode '0755'
end

directory versioned_dir do
  mode '0755'
end

remote_file File.join(versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version)) do
  source File.join(GITHUB_FULCRUM_RELEASES_URL.call(fulcrum_version, ARCHIVE_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

remote_file File.join(versioned_dir, CHECKSUMS_FILENAME.call(fulcrum_version)) do
  source File.join(GITHUB_FULCRUM_RELEASES_URL.call(fulcrum_version, CHECKSUMS_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('sha256sums')
end

remote_file File.join(versioned_dir, SIGNATURE_FILENAME.call(fulcrum_version)) do
  source File.join(GITHUB_FULCRUM_RELEASES_URL.call(fulcrum_version, SIGNATURE_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('sha256sums_asc')
end

execute 'checksums sha256sums (fulcrum)' do
  command [*%w[sha256sum --check --ignore-missing], CHECKSUMS_FILENAME.call(fulcrum_version)]
  cwd versioned_dir

  action :nothing
end

remote_file 'Calin Culianu\'s GPG public key' do
  source GPG_KEY_CALIN_CULIANU_URL
  path '/var/fulcrum/calinkey.txt'

  mode '0644'

  checksum sha256_checksums.fetch('calinkey_txt')
end

execute 'operator user gpg import (fulcrum)' do
  command %w[gpg --import /var/fulcrum/calinkey.txt]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (fulcrum)]', :immediate

  not_if { File.exist?('/var/fulcrum/.skip-gpg-import-chef') }
end

file 'skip operator user gpg import (fulcrum)' do
  path '/var/fulcrum/.skip-gpg-import-chef'

  action :nothing
end

execute 'gpg verify tar.gz .asc signature (fulcrum)' do
  command [*%w[gpg --verify], SIGNATURE_FILENAME.call(fulcrum_version)]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd versioned_dir

  user operator_user

  action :nothing
end

execute 'extract fulcrum archive' do
  command [
    'tar',
    '-xvf', File.join(versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version)),
    '-C', versioned_dir
  ]

  only_if {
    extract_dir = File.join(versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version).delete_suffix('.tar.gz'))
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :run, 'execute[checksums sha256sums (fulcrum)]', :before
  notifies :run, 'execute[gpg verify tar.gz .asc signature (fulcrum)]', :before
end

execute 'install fulcrum' do
  command [
    'install', '-m', '0755', '-o', 'root', '-g', 'root',
    '-t', '/usr/local/bin',
    File.join(versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version).delete_suffix('.tar.gz'), 'Fulcrum'),
    File.join(versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version).delete_suffix('.tar.gz'), 'FulcrumAdmin')
  ]

  only_if { `which Fulcrum`.empty? }

  notifies :run, 'execute[extract fulcrum archive]', :before
  notifies :create, 'file[install fulcrum man page]', :immediate
end

file 'install fulcrum man page' do
  path '/usr/local/share/man/man1/Fulcrum.1'
  content lazy {
    File.read(
      File.join(
        versioned_dir, ARCHIVE_FILENAME.call(fulcrum_version).delete_suffix('.tar.gz'),
        'man', 'Fulcrum.1'
      )
    )
  }

  mode '0644'

  action :nothing

  notifies :run, 'execute[refresh mandb]', :delayed
end

execute 'refresh mandb' do
  command 'mandb'

  action :nothing
end

template '/var/fulcrum/fulcrum.conf' do
  source 'fulcrum.conf.erb'

  variables(
    fast_sync_memory_mb: params['fast_sync_memory_mb']
  )

  group lazy { Etc.getpwnam('fulcrum').gid }
  mode '0640'
end

template '/etc/systemd/system/fulcrum.service' do
  source 'fulcrum.service.erb'

  variables(
    after_units: node['bitcoin_node'].[]('service_require')&.[]('fulcrum.service')
  )

  mode '0640'
end

systemd_unit 'fulcrum.service' do
  action :enable
end

execute 'ufw allow fulcrum tcp connection' do
  command [*%w[ufw allow 50001/tcp comment], 'Allow Fulcrum (tcp)']

  not_if do
    `ufw status verbose | grep -q '50001/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow fulcrum ssl connection' do
  command [*%w[ufw allow 50002/tcp comment], 'Allow Fulcrum (ssl)']

  not_if do
    `ufw status verbose | grep -q '50002/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

ruby_block 'tor hidden service (fulcrum)' do
  block do
    node.override['rpi4_server']['tor']['hidden_services'] = [
      *node['rpi4_server']['tor']['hidden_services'],
      <<~TORRC
        # Hidden service (Fulcrum, TCP)
        HiddenServiceDir /var/lib/tor/hidden_service_fulcrum_tcp/
        HiddenServiceVersion 3
        HiddenServicePort 50001 127.0.0.1:50001

        # Hidden service (Fulcrum, SSL)
        HiddenServiceDir /var/lib/tor/hidden_service_fulcrum_ssl/
        HiddenServiceVersion 3
        HiddenServicePort 50002 127.0.0.1:50002
      TORRC
    ]
  end

  notifies :create, 'template[/etc/tor/torrc]', :delayed
end

cookbook_file '/var/fulcrum/fulcrum-banner.txt' do
  source 'fulcrum-banner.txt'

  group lazy { Etc.getpwnam('fulcrum').gid }
  mode '0640'
end
