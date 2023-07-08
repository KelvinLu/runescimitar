#
# Cookbook:: lightning_node
# Recipe:: lntop
#

GITHUB_LNTOP_RELEASES_URL = Proc.new { |version, filename| "https://github.com/edouardparis/lntop/releases/download/v#{version}/#{filename.call(version)}" }

ARCHIVE_FILENAME = Proc.new { |version| "lntop-v#{version}-Linux-arm64.tar.gz" }
CHECKSUMS_FILENAME = Proc.new { |version| "checksums-lntop-v#{version}.txt" }
SIGNATURE_FILENAME = Proc.new { |version| "checksums-lntop-v#{version}.txt.sig" }

GPG_KEY_EDOUARDPARIS_URL = 'https://edouard.paris/key.asc'

params            = node['lightning_node'].fetch('lntop')
operator_user     = node['rpi4_server'].fetch('operator_user')

lntop_version     = params.fetch('version')
sha256_checksums  = params.fetch('sha256_checksums')

qualified_name    = "release-v#{lntop_version}"
var_opt_directory = '/var/opt/lntop'

directory var_opt_directory do
  mode '0755'
end

remote_file File.join(var_opt_directory, ARCHIVE_FILENAME.call(lntop_version)) do
  source GITHUB_LNTOP_RELEASES_URL.call(lntop_version, ARCHIVE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

remote_file File.join(var_opt_directory, CHECKSUMS_FILENAME.call(lntop_version)) do
  source GITHUB_LNTOP_RELEASES_URL.call(lntop_version, CHECKSUMS_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('checksums_txt')
end

remote_file File.join(var_opt_directory, SIGNATURE_FILENAME.call(lntop_version)) do
  source GITHUB_LNTOP_RELEASES_URL.call(lntop_version, SIGNATURE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('checksums_txt_sig')
end

remote_file File.join(var_opt_directory, 'edouardparis-gpg-key.asc') do
  source GPG_KEY_EDOUARDPARIS_URL

  mode '0644'

  checksum sha256_checksums.fetch('edouardparis_gpg_key')
end

execute 'checksums sha256sums (lntop)' do
  command [*%w[sha256sum --ignore-missing --check], CHECKSUMS_FILENAME.call(lntop_version)]
  cwd var_opt_directory

  action :nothing
end

execute 'operator user gpg import (lntop)' do
  command [*%w[gpg --import], File.join(var_opt_directory, 'edouardparis-gpg-key.asc')]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })

  user operator_user

  notifies :create_if_missing, 'file[skip operator user gpg import (lntop)]', :immediate

  not_if { File.exist?(File.join(var_opt_directory, '.skip-gpg-import-chef')) }
end

file 'skip operator user gpg import (lntop)' do
  path File.join(var_opt_directory, '.skip-gpg-import-chef')

  action :nothing
end

execute 'gpg verify checksums signature (lntop)' do
  command [*%w[gpg --verify], SIGNATURE_FILENAME.call(lntop_version), CHECKSUMS_FILENAME.call(lntop_version)]
  environment ({ 'HOME' => Dir.home(operator_user), 'USER' => operator_user })
  cwd var_opt_directory

  user operator_user

  action :nothing
end

directory 'lntop archive extracted directory' do
  path File.join(var_opt_directory, qualified_name)
  mode '0755'

  action :nothing
end

execute 'extract lntop archive' do
  command [
    'tar',
    '-xvf', File.join(var_opt_directory, ARCHIVE_FILENAME.call(lntop_version)),
    '-C', var_opt_directory
  ]

  only_if {
    extract_dir = File.join(var_opt_directory, qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :run, 'execute[checksums sha256sums (lntop)]', :before
  notifies :run, 'execute[gpg verify checksums signature (lntop)]', :before
  notifies :create_if_missing, 'directory[lntop archive extracted directory]', :before
end

execute 'install lntop' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/usr/local/bin',
      File.join(var_opt_directory, qualified_name, 'lntop')
    ]
  }

  only_if { `which lntop`.empty? }

  notifies :run, 'execute[extract lntop archive]', :before
end

directory '/opt/lntop' do
  mode '0755'
end

directory '/opt/lntop/bin' do
  mode '0755'
end

file '/opt/lntop/lntop-wrapper.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      char *environment[] = {
        "TERM=rxvt-unicode-256color",
        "PATH=/usr/bin",
        0
      };

      execve("/usr/local/bin/lntop", argv, environment);
    }
  PROGRAM

  mode '0644'
end

execute 'compile lntop wrapper' do
  command %w[gcc lntop-wrapper.c -o bin/lntop]
  cwd '/opt/lntop'

  creates '/opt/lntop/bin/lntop'
end
