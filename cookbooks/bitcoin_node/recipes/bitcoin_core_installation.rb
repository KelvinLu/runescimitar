#
# Cookbook:: bitcoin_node
# Recipe:: bitcoin_core_installation
#
# Copyright:: 2022, The Authors, All Rights Reserved.

require 'json'
require 'fileutils'

BITCOIN_CORE = 'https://bitcoincore.org'

operator_user         = node['rpi4_server'].fetch('operator_user')
bitcoin_core_version  = node['bitcoin_node'].fetch('bitcoin_core_version')
checksums             = node['bitcoin_node'].fetch('sha256_checksums')
github_repo_id        = node['bitcoin_node'].fetch('gpg_trust_builder_keys').fetch('github_repository_id')

versioned_name    = "bitcoin-#{bitcoin_core_version}"
qualified_name    = "bitcoin-core-#{bitcoin_core_version}"
var_opt_directory = File.join('/var/opt/bitcoin/', qualified_name)

download_prefix = URI.join(BITCOIN_CORE, File.join('bin', qualified_name)).to_s
archive_package = "bitcoin-#{bitcoin_core_version}-aarch64-linux-gnu.tar.gz"

builder_keys_uri = URI.join(
  'https://api.github.com',
  File.join('repositories', "#{github_repo_id}", 'contents', 'builder-keys')
)

include_recipe 'rpi4_server::opentimestamps'

directory '/var/opt/bitcoin' do
  mode '0755'
end

directory var_opt_directory do
  mode '0755'
end

remote_file File.join(var_opt_directory, archive_package) do
  source File.join(download_prefix, archive_package)

  mode '0644'

  checksum checksums.fetch('archive_targz')
end

remote_file File.join(var_opt_directory, 'SHA256SUMS') do
  source File.join(download_prefix, 'SHA256SUMS')

  mode '0644'

  checksum checksums.fetch('sha256sums')
end

remote_file File.join(var_opt_directory, 'SHA256SUMS.asc') do
  source File.join(download_prefix, 'SHA256SUMS.asc')

  mode '0644'

  checksum checksums.fetch('sha256sums_asc')
end

remote_file File.join(var_opt_directory, 'SHA256SUMS.ots') do
  source File.join(download_prefix, 'SHA256SUMS.ots')

  mode '0644'

  checksum checksums.fetch('sha256sums_ots')
end

execute 'checksums sha256sums (bitcoin core)' do
  command %w[sha256sum --ignore-missing --check SHA256SUMS]
  cwd var_opt_directory

  action :nothing
end

directory File.join(var_opt_directory, 'builder-keys') do
  mode '0755'
end

ruby_block 'download builder-keys guix.sigs' do
  block do
    builder_keys_api_response =
      Chef::HTTP.new("#{builder_keys_uri.scheme}://#{builder_keys_uri.host}")
        .get(builder_keys_uri.path)

    github_content_http = Chef::HTTP.new("https://raw.githubusercontent.com/")

    JSON.parse(builder_keys_api_response).each do |builder_key|
      name = builder_key['name']
      gpg_content = github_content_http.get(URI(builder_key['download_url']).path)

      File.write(File.join(var_opt_directory, 'builder-keys', name), gpg_content)
    end

    FileUtils.touch(File.join(var_opt_directory, 'builder-keys', '.skip-download-chef'))
  end

  not_if { File.exist?(File.join(var_opt_directory, 'builder-keys', '.skip-download-chef')) }
end

execute 'operator user gpg import (bitcoin core)' do
  command lazy { "gpg --import #{Dir[File.join(var_opt_directory, 'builder-keys', '*.gpg')].join(' ')}" }
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (bitcoin core)]', :immediate

  not_if { File.exist?(File.join(var_opt_directory, 'builder-keys', '.skip-gpg-import-chef')) }
end

file 'skip operator user gpg import (bitcoin core)' do
  path File.join(var_opt_directory, 'builder-keys', '.skip-gpg-import-chef')

  action :nothing
end

execute 'gpg verify sha256sums .asc signature (bitcoin core)' do
  command %w[gpg --verify SHA256SUMS.asc]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user

  action :nothing
end

execute 'verify opentimestamps (bitcoin core)' do
  command lazy {
    [
      'ots',
      *(local_bitcoind_listening? ? nil : '--no-bitcoin'), '--no-cache',
      'verify', 'SHA256SUMS.ots', '-f', 'SHA256SUMS'
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

directory 'bitcoin archive extracted directory' do
  path File.join(var_opt_directory, qualified_name)
  mode '0755'

  action :nothing
end

execute 'extract bitcoin archive' do
  command [
    'tar',
    '-xvf', File.join(var_opt_directory, archive_package),
    '-C', var_opt_directory
  ]

  only_if {
    extract_dir = File.join(var_opt_directory, qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :run, 'execute[checksums sha256sums (bitcoin core)]', :before
  notifies :run, 'execute[gpg verify sha256sums .asc signature (bitcoin core)]', :before
  notifies :run, 'execute[verify opentimestamps (bitcoin core)]', :before
  notifies :create_if_missing, 'directory[bitcoin archive extracted directory]', :before
end

execute 'install bitcoin core' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/usr/local/bin',
      *(Dir[File.join(var_opt_directory, versioned_name, 'bin', '*')])
    ]
  }

  only_if { `which bitcoind`.empty? }

  notifies :run, 'execute[extract bitcoin archive]', :before
end
