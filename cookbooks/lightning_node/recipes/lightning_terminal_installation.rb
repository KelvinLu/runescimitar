#
# Cookbook:: lightning_node
# Recipe:: lightning_terminal_installation
#

GITHUB_LIT_RELEASES_URL = Proc.new { |version, filename| "https://github.com/lightninglabs/lightning-terminal/releases/download/v#{version}/#{filename.call(version)}" }

ARCHIVE_FILENAME = Proc.new { |version| "lightning-terminal-linux-arm64-v#{version}.tar.gz" }
MANIFEST_FILENAME = Proc.new { |version| "manifest-v#{version}.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "manifest-v#{version}.sig" }
OTS_FILENAME = Proc.new { |version| "manifest-v#{version}.sig.ots" }

GPG_KEY_VTIGERSTROM_FINGERPRINT = '187F6ADD93AE3B0CF335AA6AB984570980684DCC'

params                      = node['lightning_node'].fetch('lightning_terminal')
neutrino_mode               = !(node['lightning_node'].fetch('lnd')['neutrino_mode'].nil?)
operator_user               = node['rpi4_server'].fetch('operator_user')

lightning_terminal_version  = params.fetch('version')
sha256_checksums            = params.fetch('sha256_checksums')

versioned_name              = "lightning-terminal-#{lightning_terminal_version}"
qualified_name              = "lightning-terminal-linux-arm64-v#{lightning_terminal_version}"
var_opt_directory           = File.join('/var/opt/lightning-terminal/', versioned_name)

directory '/var/opt/lightning-terminal' do
  mode '0755'
end

directory var_opt_directory do
  mode '0755'
end

remote_file File.join(var_opt_directory, ARCHIVE_FILENAME.call(lightning_terminal_version)) do
  source GITHUB_LIT_RELEASES_URL.call(lightning_terminal_version, ARCHIVE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

remote_file File.join(var_opt_directory, MANIFEST_FILENAME.call(lightning_terminal_version)) do
  source GITHUB_LIT_RELEASES_URL.call(lightning_terminal_version, MANIFEST_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_txt')
end

remote_file File.join(var_opt_directory, SIGNATURE_FILENAME.call(lightning_terminal_version)) do
  source GITHUB_LIT_RELEASES_URL.call(lightning_terminal_version, SIGNATURE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_sig')
end

remote_file File.join(var_opt_directory, OTS_FILENAME.call(lightning_terminal_version)) do
  source GITHUB_LIT_RELEASES_URL.call(lightning_terminal_version, OTS_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_sig_ots')
end

execute 'checksums sha256sums (lightning terminal)' do
  command [*%w[sha256sum --ignore-missing --check], MANIFEST_FILENAME.call(lightning_terminal_version)]
  cwd var_opt_directory

  action :nothing
end

execute 'operator user gpg import (lightning terminal)' do
  command [*%w[gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys], GPG_KEY_VTIGERSTROM_FINGERPRINT]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (lightning terminal)]', :immediate

  not_if { File.exist?(File.join(var_opt_directory, '.skip-gpg-import-chef')) }
end

file 'skip operator user gpg import (lightning terminal)' do
  path File.join(var_opt_directory, '.skip-gpg-import-chef')

  action :nothing
end

execute 'gpg verify manifest signature (lightning terminal)' do
  command [*%w[gpg --verify], SIGNATURE_FILENAME.call(lightning_terminal_version), MANIFEST_FILENAME.call(lightning_terminal_version)]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user

  action :nothing
end

execute 'verify opentimestamps (lightning terminal)' do
  command lazy {
    [
      'ots',
      *(local_bitcoind_listening? ? nil : '--no-bitcoin'), '--no-cache',
      'verify', OTS_FILENAME.call(lightning_terminal_version), '-f', SIGNATURE_FILENAME.call(lightning_terminal_version)
    ]
  }
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user
  group 'bitcoin' unless neutrino_mode

  returns lazy {
    [0, *(local_bitcoind_listening? ? nil : 1)]
  }

  action :nothing
end

directory 'lightning terminal archive extracted directory' do
  path File.join(var_opt_directory, qualified_name)
  mode '0755'

  action :nothing
end

execute 'extract lightning terminal archive' do
  command [
    'tar',
    '-xvf', File.join(var_opt_directory, ARCHIVE_FILENAME.call(lightning_terminal_version)),
    '-C', var_opt_directory
  ]

  only_if {
    extract_dir = File.join(var_opt_directory, qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :run, 'execute[checksums sha256sums (lightning terminal)]', :before
  notifies :run, 'execute[gpg verify manifest signature (lightning terminal)]', :before
  notifies :run, 'execute[verify opentimestamps (lightning terminal)]', :before
  notifies :create_if_missing, 'directory[lightning terminal archive extracted directory]', :before
end

execute 'install lightning terminal' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/usr/local/bin',
      *(Dir[File.join(var_opt_directory, qualified_name, '*')])
    ]
  }

  only_if { `which litd`.empty? }

  notifies :run, 'execute[extract lightning terminal archive]', :before
end
