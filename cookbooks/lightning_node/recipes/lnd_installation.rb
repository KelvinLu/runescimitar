#
# Cookbook:: lightning_node
# Recipe:: lnd_installation
#

GITHUB_LND_RELEASES_URL = Proc.new { |version, filename| "https://github.com/lightningnetwork/lnd/releases/download/v#{version}/#{filename.call(version)}" }

ARCHIVE_FILENAME = Proc.new { |version| "lnd-linux-arm64-v#{version}.tar.gz" }
MANIFEST_FILENAME = Proc.new { |version| "manifest-v#{version}.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "manifest-roasbeef-v#{version}.sig" }
OTS_FILENAME = Proc.new { |version| "manifest-roasbeef-v#{version}.sig.ots" }

GPG_KEY_ROASBEEF_URL = 'https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc'

params            = node['lightning_node'].fetch('lnd')
operator_user     = node['rpi4_server'].fetch('operator_user')

lnd_version       = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')

versioned_name    = "lnd-#{lnd_version}"
qualified_name    = "lnd-linux-arm64-v#{lnd_version}"
var_opt_directory = File.join('/var/opt/lnd/', versioned_name)

directory '/var/opt/lnd' do
  mode '0755'
end

directory var_opt_directory do
  mode '0755'
end

remote_file File.join(var_opt_directory, ARCHIVE_FILENAME.call(lnd_version)) do
  source GITHUB_LND_RELEASES_URL.call(lnd_version, ARCHIVE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

remote_file File.join(var_opt_directory, MANIFEST_FILENAME.call(lnd_version)) do
  source GITHUB_LND_RELEASES_URL.call(lnd_version, MANIFEST_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_txt')
end

remote_file File.join(var_opt_directory, SIGNATURE_FILENAME.call(lnd_version)) do
  source GITHUB_LND_RELEASES_URL.call(lnd_version, SIGNATURE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_sig')
end

remote_file File.join(var_opt_directory, OTS_FILENAME.call(lnd_version)) do
  source GITHUB_LND_RELEASES_URL.call(lnd_version, OTS_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('manifest_sig_ots')
end

remote_file File.join(var_opt_directory, File.basename(GPG_KEY_ROASBEEF_URL)) do
  source GPG_KEY_ROASBEEF_URL

  mode '0644'

  checksum sha256_checksums.fetch('roasbeef_gpg_key')
end

execute 'checksums sha256sums (lnd)' do
  command [*%w[sha256sum --ignore-missing --check], MANIFEST_FILENAME.call(lnd_version)]
  cwd var_opt_directory

  action :nothing
end

execute 'operator user gpg import (lnd)' do
  command [*%w[gpg --import], File.join(var_opt_directory, File.basename(GPG_KEY_ROASBEEF_URL))]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (lnd)]', :immediate

  not_if { File.exist?(File.join(var_opt_directory, '.skip-gpg-import-chef')) }
end

file 'skip operator user gpg import (lnd)' do
  path File.join(var_opt_directory, '.skip-gpg-import-chef')

  action :nothing
end

execute 'gpg verify manifest signature (lnd)' do
  command [*%w[gpg --verify], SIGNATURE_FILENAME.call(lnd_version), MANIFEST_FILENAME.call(lnd_version)]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user

  action :nothing
end

execute 'verify opentimestamps (lnd)' do
  command lazy {
    [
      'ots',
      *(local_bitcoind_listening? ? nil : '--no-bitcoin'), '--no-cache',
      'verify', OTS_FILENAME.call(lnd_version), '-f', SIGNATURE_FILENAME.call(lnd_version)
    ]
  }
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user
  group 'bitcoin'

  returns lazy {
    [0, *(local_bitcoind_listening? ? nil : 1)]
  }

  action :nothing
end

directory 'lnd archive extracted directory' do
  path File.join(var_opt_directory, qualified_name)
  mode '0755'

  action :nothing
end

execute 'extract lnd archive' do
  command [
    'tar',
    '-xvf', File.join(var_opt_directory, ARCHIVE_FILENAME.call(lnd_version)),
    '-C', var_opt_directory
  ]

  only_if {
    extract_dir = File.join(var_opt_directory, qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :run, 'execute[checksums sha256sums (lnd)]', :before
  notifies :run, 'execute[gpg verify manifest signature (lnd)]', :before
  notifies :run, 'execute[verify opentimestamps (lnd)]', :before
  notifies :create_if_missing, 'directory[lnd archive extracted directory]', :before
end

execute 'install lnd' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/usr/local/bin',
      *(Dir[File.join(var_opt_directory, qualified_name, '*')])
    ]
  }

  only_if { `which lnd`.empty? }

  notifies :run, 'execute[extract lnd archive]', :before
end
