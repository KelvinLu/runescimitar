#
# Cookbook:: applications
# Recipe:: sparrow
#
# Copyright:: 2022, The Authors, All Rights Reserved.

GITHUB_SPARROW_RELEASES_URL = Proc.new { |version, filename| "https://github.com/sparrowwallet/sparrow/releases/download/#{version}/#{filename.call(version)}" }

SPARROW_DESKTOP_ARCHIVE_FILENAME = Proc.new { |version| "sparrow-#{version}-x86_64.tar.gz" }
CHECKSUMS_FILENAME = Proc.new { |version| "sparrow-#{version}-manifest.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "sparrow-#{version}-manifest.txt.asc" }

GPG_KEY_CRAIG_RAW_URL = 'https://keybase.io/craigraw/pgp_keys.asc'

params            = node['applications'].fetch('sparrow')

sparrow_version   = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')

versioned_name    = "sparrow-#{sparrow_version}"
versioned_dir     = File.join('/var/opt/sparrow/', versioned_name)

directory '/opt/sparrow-desktop' do
  mode '0755'
end

directory '/var/opt/sparrow' do
  mode '0755'
end

directory versioned_dir do
  mode '0755'
end

remote_file File.join(versioned_dir, SPARROW_DESKTOP_ARCHIVE_FILENAME.call(sparrow_version)) do
  source File.join(GITHUB_SPARROW_RELEASES_URL.call(sparrow_version, SPARROW_DESKTOP_ARCHIVE_FILENAME))

  mode '0644'

  checksum sha256_checksums.fetch('sparrow_desktop')
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

node['applications']&.[]('sparrow')&.[]('users').each do |user|
  execute 'operator user gpg import (fulcrum)' do
    command [*%w[gpg --import], File.join(versioned_dir, 'craig-raw.gpg.asc')]
    environment ({ 'HOME' => Dir.home(user), 'USER' => user })

    user user

    notifies :create_if_missing, 'file[skip operator user gpg import (sparrow)]', :immediate

    not_if { File.exist?(File.join(versioned_dir, ".skip-gpg-import-chef_#{user}") ) }
  end

  file 'skip operator user gpg import (sparrow)' do
    path File.join(versioned_dir, ".skip-gpg-import-chef_#{user}")

    user user
    group user
    mode '0644'

    action :nothing
  end

  execute "gpg verify manifest.txt.asc (sparrow) for user #{user}" do
    command [*%w[gpg --verify], SIGNATURE_FILENAME.call(sparrow_version)]
    environment ({ 'HOME' => Dir.home(user), 'USER' => user })
    cwd versioned_dir

    user user

    action :nothing
  end
end

execute 'extract sparrow desktop archive' do
  command [
    'tar',
    '-xvf', File.join(versioned_dir, SPARROW_DESKTOP_ARCHIVE_FILENAME.call(sparrow_version)),
    '--strip-components', '1',
    '-C', '/opt/sparrow-desktop'
  ]

  creates '/opt/sparrow-desktop/bin/Sparrow'

  only_if { Dir.empty?('/opt/sparrow-desktop') }

  node['applications']&.[]('sparrow')&.[]('users').each do |user|
    notifies :run, "execute[gpg verify manifest.txt.asc (sparrow) for user #{user}]", :before
  end
  notifies :run, 'execute[checksums sha256sums (sparrow)]', :before
  notifies :delete, 'directory[/opt/sparrow-desktop]', :before
  notifies :create, 'directory[/opt/sparrow-desktop]', :before
end

link '/usr/local/bin/Sparrow' do
  to '/opt/sparrow-desktop/bin/Sparrow'
end

node['applications']&.[]('sparrow')&.[]('users').each do |user|
  directory File.join(Dir.home(user), '.sparrow') do
    user user
    group user
    mode '0750'
  end

  cookbook_file File.join(Dir.home(user), '.sparrow', 'config') do
    source 'sparrow-config'

    user user
    group user
    mode '0640'

    action :create_if_missing
  end

  directory File.join(Dir.home(user), '.sparrow', 'wallets') do
    user user
    group user
    mode '0750'
  end

  directory File.join(Dir.home(user), '.sparrow', 'wallets', 'remote') do
    user user
    group user
    mode '0750'
  end

  cookbook_file File.join(Dir.home(user), '.sparrow', 'mount-remote-workspace') do
    source 'sparrow-mount-remote-workspace'

    user user
    group user
    mode '0750'
  end

  cookbook_file File.join(Dir.home(user), '.sparrow', 'mount-remote-workspace') do
    source 'sparrow-mount-remote-workspace'

    user user
    group user
    mode '0750'
  end

  cookbook_file File.join(Dir.home(user), '.sparrow', 'forward-electrum-port') do
    source 'sparrow-forward-electrum-port'

    user user
    group user
    mode '0750'
  end

  cookbook_file File.join(Dir.home(user), '.sparrow', 'connect-remote') do
    source 'sparrow-connect-remote'

    user user
    group user
    mode '0750'
  end
end
