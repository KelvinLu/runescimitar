#
# Cookbook:: bitcoin_node
# Recipe:: sparrow
#
# Copyright:: 2022, The Authors, All Rights Reserved.

GITHUB_SPARROW_RELEASES_URL = Proc.new { |version, filename| "https://github.com/sparrowwallet/sparrow/releases/download/#{version}/#{filename.call(version)}" }

SPARROW_SERVER_ARCHIVE_FILENAME = Proc.new { |version| "sparrow-server-#{version}-aarch64.tar.gz" }
CHECKSUMS_FILENAME = Proc.new { |version| "sparrow-#{version}-manifest.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "sparrow-#{version}-manifest.txt.asc" }

GPG_KEY_CRAIG_RAW_URL = 'https://keybase.io/craigraw/pgp_keys.asc'

params            = node['bitcoin_node'].fetch('sparrow')
operator_user     = node['rpi4_server'].fetch('operator_user')

sparrow_version   = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')

versioned_name    = "sparrow-#{sparrow_version}"
versioned_dir     = File.join('/var/opt/sparrow/', versioned_name)

directory '/opt/sparrow-server' do
  mode '0755'
end

directory '/var/opt/sparrow' do
  mode '0755'
end

directory versioned_dir do
  mode '0755'
end

remote_file File.join(versioned_dir, SPARROW_SERVER_ARCHIVE_FILENAME.call(sparrow_version)) do
  source File.join(GITHUB_SPARROW_RELEASES_URL.call(sparrow_version, SPARROW_SERVER_ARCHIVE_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('sparrow_server')
end

remote_file File.join(versioned_dir, CHECKSUMS_FILENAME.call(sparrow_version)) do
  source File.join(GITHUB_SPARROW_RELEASES_URL.call(sparrow_version, CHECKSUMS_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('manifest_txt')
end

remote_file File.join(versioned_dir, SIGNATURE_FILENAME.call(sparrow_version)) do
  source File.join(GITHUB_SPARROW_RELEASES_URL.call(sparrow_version, SIGNATURE_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('manifest_txt_asc')
end

execute 'checksums sha256sums (sparrow)' do
  command [*%w[sha256sum --check --ignore-missing], CHECKSUMS_FILENAME.call(sparrow_version)]
  cwd versioned_dir

  action :nothing
end

remote_file 'Craig Raw\'s GPG public key' do
  source GPG_KEY_CRAIG_RAW_URL
  path File.join(versioned_dir, 'craig-raw.gpg.asc')

  mode '0644'

  checksum sha256_checksums.fetch('craig_raw_gpg_key')
end

execute 'operator user gpg import (fulcrum)' do
  command [*%w[gpg --import], File.join(versioned_dir, 'craig-raw.gpg.asc')]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (sparrow)]', :immediate

  not_if { File.exist?(File.join(versioned_dir, '.skip-gpg-import-chef') ) }
end

file 'skip operator user gpg import (sparrow)' do
  path File.join(versioned_dir, '.skip-gpg-import-chef')

  action :nothing
end

execute 'gpg verify manifest.txt.asc (sparrow)' do
  command [*%w[gpg --verify], SIGNATURE_FILENAME.call(sparrow_version)]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd versioned_dir

  user operator_user

  action :nothing
end

execute 'extract sparrow server archive' do
  command [
    'tar',
    '-xvf', File.join(versioned_dir, SPARROW_SERVER_ARCHIVE_FILENAME.call(sparrow_version)),
    '--strip-components', '1',
    '-C', '/opt/sparrow-server'
  ]

  creates '/opt/sparrow-server/bin/Sparrow'

  notifies :run, 'execute[checksums sha256sums (sparrow)]', :before
  notifies :run, 'execute[gpg verify manifest.txt.asc (sparrow)]', :before
  notifies :delete, 'directory[/opt/sparrow-server]', :before
  notifies :create, 'directory[/opt/sparrow-server]', :before
end
